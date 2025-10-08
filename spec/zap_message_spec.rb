require_relative 'spec_helper'
require_relative '../lib/zap_message'

RSpec.describe ZapMessage do
  it 'has a version number' do
    expect(ZapMessage::Version.version).to eq('0.2.0')
  end
end
