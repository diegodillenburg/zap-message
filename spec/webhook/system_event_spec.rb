# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/zap_message'

RSpec.describe ZapMessage::Webhook::SystemEvent do
  let(:message) do
    {
      'id' => 'wamid.system123',
      'timestamp' => '1609459200',
      'type' => 'system',
      'from' => '5511999999999',
      'from_user_id' => 'BR.99887766554433221100',
      'system' => {
        'body' => 'User A changed their phone number',
        'type' => 'user_changed_number',
        'wa_id' => '5511888888888',
        'user_id' => 'BR.11223344556677889900'
      }
    }
  end
  let(:event) { described_class.new(message: message) }

  it 'reports its type as :system' do
    expect(event.type).to eq(:system)
  end

  it 'exposes the message id and identifiers' do
    expect(event.message_id).to eq('wamid.system123')
    expect(event.from).to eq('5511999999999')
    expect(event.from_user_id).to eq('BR.99887766554433221100')
  end

  it 'exposes the system change details' do
    expect(event.system_type).to eq('user_changed_number')
    expect(event.body).to eq('User A changed their phone number')
  end

  it 'exposes the new wa_id and regenerated BSUID' do
    expect(event.new_wa_id).to eq('5511888888888')
    expect(event.new_user_id).to eq('BR.11223344556677889900')
  end

  it 'flags a number change' do
    expect(event.number_changed?).to be true
    expect(event.identity_changed?).to be false
  end

  context 'when the system block is absent' do
    let(:message) { { 'id' => 'wamid.x', 'type' => 'system' } }

    it 'degrades gracefully' do
      expect(event.system).to eq({})
      expect(event.system_type).to be_nil
      expect(event.number_changed?).to be false
    end
  end
end
