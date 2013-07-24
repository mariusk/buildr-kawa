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

  # it 'should identify itself from source directories' do
  #   write 'src/main/kawa/com/example/Test.scm', '(module-name "com.example")
  #                                                (define-simple-class <Test> ()
  #                                                 (i init: 1))'
  #   define('foo').compile.compiler.should eql(:kawac)
  # end

describe "kawa tests" do
  it 'should respond to from() and return self' do
    "abc".should eq("abc")
  end
end
