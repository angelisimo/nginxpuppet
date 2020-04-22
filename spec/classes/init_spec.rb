require 'spec_helper'
describe 'nginxproxy' do
  context 'with default values for all parameters' do
    it { should contain_class('nginxproxy') }
  end
end
