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

# Again, modelled on the similar scala code.

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helpers'))

describe 'kawa compiler options' do

  def compile_task
    @compile_task ||= define('foo').compile.using(:kawac)
  end

  def kawac_args
    compile_task.instance_eval { @compiler }.send(:kawac_args)
  end

  it 'requires present KAWA_HOME' do
    ENV['KAWA_HOME'].should_not be_nil
  end

  it 'should set warnings options to true by default' do
    compile_task.options.warnings should be_true
  end

  it 'should set warnings option to true when running with --verbose option' do
    verbose true
    compile_task.options.warnings.should be_true
    verbose false
  end

  it 'should include all warnings when warnings is true' do
    compile_task.using(:warnings => true)
    kawac_args.should include('--warn-undefined-variable')
    kawac_args.should include('--warn-invoke-unknown-method')
    kawac_args.should include('--warn-as-error')
  end

  it 'should not warn as error when warnings is false' do
    compile_task.using(:warnings => false)
    kawac_args.should_not include('--warn-as-error')
  end
  
  it 'should set optimize option to false by default' do
    compile_task.options.optimise.should be_false
  end

  it 'should inherit options from parent' do
    define 'foo' do
      compile.using(:warnings=>false, :debug=>true)
      define 'bar' do
        compile.using(:kawac)
        compile.options.warnings.should be_false
        compile.options.debug.should be_true
      end
    end
  end
end

describe 'kawa compiler' do

  it 'should identify itself from source directories' do
    write 'src/main/kawa/com/example/Test.scm',
'(module-name com.example.)
  (define-simple-class <Test> ()
  (i init: 1))
'
    define('foo').compile.compiler.should eql(:kawac)
  end

  it 'should report the language as :kawa' do
    define('foo').compile.using(:kawac).language.should eql(:kawa)
  end

  it 'should set the target directory to target/classes' do
    define 'foo' do
      lambda { compile.using(:kawac) }.should change { compile.target.to_s }.to(File.expand_path('target/classes'))
    end
  end

  it 'should not override existing target directory' do
    define 'foo' do
      compile.into('classes')
      lambda { compile.using(:kawac) }.should_not change { compile.target }
    end
  end

  it 'should not change existing list of sources' do
    define 'foo' do
      compile.from('sources')
      lambda { compile.using(:kawac) }.should_not change { compile.sources }
    end
  end

  it 'should include as classpath dependency' do
    write 'src/dependency/Dependency.scm', '(define-simple-class <Dependency> ())'
    define 'dependency', :version=>'1.0' do
      compile.using(:warnings=>false)
      compile.from('src/dependency').into('target/dependency')
      package(:jar)
    end
    write 'src/test/DependencyTest.scm', '(define-simple-class <DependencyTest> () (d init: Dependency))'
    lambda { define('foo').compile.using(:warnings => false).from('src/test').with(project('dependency')).invoke }.should run_task('foo:compile')
    file('target/classes/DependencyTest.class').should exist
  end

  def define_test1_project
    write 'src/main/kawa/com/example/Test1.scm',
'(module-name com.example.)
(define-simple-class Test1 ()
  (i init: 1))
'
    define 'test1', :version=>'1.0' do
      package(:jar)
    end
  end

  it 'should compile a simple .scm file into a class file' do
    define_test1_project
    task('test1:compile').invoke
    file('target/classes/com/example/Test1.class').should exist
  end

  it 'should package .class into a .jar file' do
    define_test1_project
    task('test1:package').invoke
    file('target/test1-1.0.jar').should exist
    Zip::ZipFile.open(project('test1').package(:jar).to_s) do |zip|
      zip.file.exists?('com/example/Test1.class').should be_true
    end
  end

  it 'should compile kawa class depending on java class in same project' do
    write 'src/main/java/com/example/Foo.java', 'package com.example; public class Foo {}'
    write 'src/main/kawa/com/example/Bar.scm', '
(module-name com.example.)
(define-simple-class Bar (Foo))
'
    define 'test1', :version=>'1.0' do
      package(:jar)
    end
    task('test1:package').invoke
    file('target/test1-1.0.jar').should exist
    #sleep 1000
    Zip::ZipFile.open(project('test1').package(:jar).to_s) do |zip|
      zip.file.exist?('com/example/Foo.class').should be_true
      zip.file.exist?('com/example/Bar.class').should be_true
    end
  end

  it 'should compile java class depending on kawa class in same project' do
    write 'src/main/kawa/com/example/Foo.scm', '
(module-name com.example.)
(define-simple-class Foo ())
'
    write 'src/main/java/com/example/Bar.java',  'package com.example; public class Bar extends Foo {}'
    define 'test1', :version=>'1.0' do
      package(:jar)
    end
    task('test1:package').invoke
    file('target/test1-1.0.jar').should exist
    Zip::ZipFile.open(project('test1').package(:jar).to_s) do |zip|
      zip.file.exist?('com/example/Foo.class').should be_true
      zip.file.exist?('com/example/Bar.class').should be_true
    end
  end

end
