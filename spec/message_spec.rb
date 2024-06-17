# frozen_string_literal: true

require_relative '../lib/message'

RSpec.describe Message do

  subject { described_class.new }

  it { expect(subject.class.name).to eq('Message') }
end
