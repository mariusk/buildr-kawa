# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#
# # Shamelessly modelled on the scala plugin already contributed to buildr.

# The Kawa Module
module Buildr::Kawa
  class Kawac < Buildr::Compiler::Base
    class << self
      def kawa_home
        env_home = ENV['KAWA_HOME']
        # TODO: Check env_home and add a trailing "/" if missing.
        @home ||= (if !env_home.nil? && File.exists?(env_home+'kawa.jar')
                     env_home
                   else
                     nil
                   end)
        
      end

      def installed?
        !kawa.home.nil?
      end

      def dependencies
        kawa_dependencies = ['kawa'].map { |s| File.expand_path("#{s}.jar", kawa_home) }
      end

      def applies_to?(project, task)
        paths = task.sources + [sources].flatten.map { |src| Array(project.path_to(:source, task.usage, src.to_sym)) }
        paths.flatten!
        paths.any? { |path| !Dir["#{path}/**/*.scm"].empty? }
      end
    end

    Javac = Buildr::Compiler::Javac

    OPTIONS = []

    Java.classpath << lambda { dependencies }

    specify :language => :kawa, :sources => [:kawa, :java], :source_ext => [:kawa, :java],
    :target => 'classes', :target_ext => 'class', :packaging => :jar

    def initialize(project, options)
      super
      options[:javac] ||= {}
      @java = Javac.new(project, options[:javac])
    end

    def compile(sources, target, dependencies)
      compile_with_kawac(sources, target, dependencies)
    end

    def compile_with_kawac(sources, target, dependencies)
      check_options(options, [:source, :target, :javac])
      java_sources = java_sources(sources)
      kawa_sources = kawa_sources(sources)

      cmd_args = []
      source_paths = sources.select { |source| File.directory?(source) }
      cp = dependencies.join(':')
      cp += ':'+source_paths.join(':') unless source_paths.empty?
      cmd_args << 'kawa'
      cmd_args << "-d" << File.expand_path(target)
      cmd_args += kawac_args
      cmd_args << "-C"
      cmd_args += kawa_sources
      
      unless Buildr.application.options.dryrun
        trace((['kawac'] + [':'] + cmd_args).join(' '))
        execstr = cmd_args.join(' ')
        result = system({'CLASSPATH' => cp}, execstr)

        unless java_sources.empty?
          trace 'Compiling mixed Java/Kawa(.scm) sources'
          deps = dependencies + Kawac.dependencies + [ File.expand_path(target) ]
          @java.compile(java_sources, target, deps)
        end
      end
    end
  
    protected
    
    def compile_map(sources, target)
      target_ext = self.class.target_ext
      ext_glob = Array(self.class.source_ext).join(',')
      sources.flatten.map{|f| File.expand_path(f)}.inject({}) do |map, source|
        sources = if File.directory?(source)
                    FileList["#{source}/**/*.{#{ext_glob}}"].reject { |file| File.directory?(file) }
                  else
                    [source]
                  end
        sources.each do |source|
          if ['.java', '.scm'].include? File.extname(source)
            name = File.basename(source).split(".")[0]
            package = findFirst(source, /^\s*package\s+([^\s;]+)\s*;?\s*/)
            packages = count(source, /^\s*package\s+([^\s;]+)\s*;?\s*/)
            # Kawa specific, not sure how this is actually used. Just blindly modelled on what I understood
            # from the similar scala code.
            found = findFirst(source, /(\(define-alias\s+\S+\s+(#{name}))/) # Maybe add support for define-namespace??
            
            if (found && packages == 1)
              map[source] = package ? File.join(target, package[1].gsub('.', '/'), name.ext(target_ext)) : target
            else
              map[source] = target
            end
            
          elsif
            map[source] = target
          end
        end
        
        map.each do |key, value|
          map[key] = first_file unless map[key]
        end

        map
      end
    end

    private

    def count(file, pattern)
      count = 0
      File.open(file, "r") do |infile|
        while (line = infile.gets)
          count += 1 if line.match(pattern)
        end
      end
      count
    end


    def java_sources(sources)
      sources.flatten.map { |source| File.directory?(source) ? FileList["#{source}/**/*.java"] : source } .
        flatten.reject { |file| File.directory?(file) || File.extname(file) != '.java' }.map { |file| File.expand_path(file) }.uniq
    end

    def kawa_sources(sources)
      sources.flatten.map { |source| File.directory?(source) ? FileList["#{source}/**/*.scm"] : source } .
        flatten.reject { |file| File.directory?(file) || File.extname(file) != '.scm' }.map { |file| File.expand_path(file) }.uniq
    end

    def kawac_args
      args = []
      args
    end
  end

  module ProjectExtension
    def kawac_options
      @kawac ||= KawacOptions.new(self)
    end
  end

  class KawacOptions
    attr_writer :incremental
    
    def initialize(project)
      @project = project
    end
    
    def incremental
      @incremental || (@project.parent ? @project.parent.kawac_options.incremental : nil)
    end
  end
end

Buildr::Compiler.compilers.unshift Buildr::Kawa::Kawac

class Buildr::Project
  include Buildr::Kawa::ProjectExtension
end
