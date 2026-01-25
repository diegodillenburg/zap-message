# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/zap_message'

RSpec.describe ZapMessage::Webhook::MessageReceived do
  let(:contacts) do
    [{ 'profile' => { 'name' => 'John Doe' }, 'wa_id' => '5511999999999' }]
  end
  let(:metadata) { { 'phone_number_id' => 'phone_id_123' } }

  describe 'interactive button reply' do
    let(:message) do
      {
        'from' => '5511999999999',
        'id' => 'wamid.button123',
        'timestamp' => '1609459200',
        'type' => 'interactive',
        'interactive' => {
          'type' => 'button_reply',
          'button_reply' => {
            'id' => 'btn_confirm',
            'title' => 'Confirm'
          }
        }
      }
    end
    let(:event) { described_class.new(message: message, contacts: contacts, metadata: metadata) }

    it 'returns true for interactive_reply?' do
      expect(event.interactive_reply?).to be true
    end

    it 'returns button_reply as interactive_type' do
      expect(event.interactive_type).to eq('button_reply')
    end

    it 'returns the interactive hash' do
      expect(event.interactive).to eq(message['interactive'])
    end

    it 'returns button_reply data' do
      expect(event.button_reply).to eq({ 'id' => 'btn_confirm', 'title' => 'Confirm' })
    end

    it 'returns button_reply_id' do
      expect(event.button_reply_id).to eq('btn_confirm')
    end

    it 'returns button_reply_title' do
      expect(event.button_reply_title).to eq('Confirm')
    end

    it 'returns nil for list_reply accessors' do
      expect(event.list_reply).to be_nil
      expect(event.list_reply_id).to be_nil
      expect(event.list_reply_title).to be_nil
      expect(event.list_reply_description).to be_nil
    end

    it 'returns button data via unified accessors' do
      expect(event.interactive_reply_id).to eq('btn_confirm')
      expect(event.interactive_reply_title).to eq('Confirm')
    end
  end

  describe 'interactive list reply' do
    let(:message) do
      {
        'from' => '5511999999999',
        'id' => 'wamid.list456',
        'timestamp' => '1609459200',
        'type' => 'interactive',
        'interactive' => {
          'type' => 'list_reply',
          'list_reply' => {
            'id' => 'option_1',
            'title' => 'Option One',
            'description' => 'First option description'
          }
        }
      }
    end
    let(:event) { described_class.new(message: message, contacts: contacts, metadata: metadata) }

    it 'returns true for interactive_reply?' do
      expect(event.interactive_reply?).to be true
    end

    it 'returns list_reply as interactive_type' do
      expect(event.interactive_type).to eq('list_reply')
    end

    it 'returns list_reply data' do
      expect(event.list_reply).to eq({
                                       'id' => 'option_1',
                                       'title' => 'Option One',
                                       'description' => 'First option description'
                                     })
    end

    it 'returns list_reply_id' do
      expect(event.list_reply_id).to eq('option_1')
    end

    it 'returns list_reply_title' do
      expect(event.list_reply_title).to eq('Option One')
    end

    it 'returns list_reply_description' do
      expect(event.list_reply_description).to eq('First option description')
    end

    it 'returns nil for button_reply accessors' do
      expect(event.button_reply).to be_nil
      expect(event.button_reply_id).to be_nil
      expect(event.button_reply_title).to be_nil
    end

    it 'returns list data via unified accessors' do
      expect(event.interactive_reply_id).to eq('option_1')
      expect(event.interactive_reply_title).to eq('Option One')
    end
  end

  describe 'non-interactive message' do
    let(:message) do
      {
        'from' => '5511999999999',
        'id' => 'wamid.text789',
        'timestamp' => '1609459200',
        'type' => 'text',
        'text' => { 'body' => 'Hello World' }
      }
    end
    let(:event) { described_class.new(message: message, contacts: contacts, metadata: metadata) }

    it 'returns false for interactive_reply?' do
      expect(event.interactive_reply?).to be false
    end

    it 'returns nil for interactive' do
      expect(event.interactive).to be_nil
    end

    it 'returns nil for interactive_type' do
      expect(event.interactive_type).to be_nil
    end

    it 'returns nil for all interactive accessors' do
      expect(event.button_reply).to be_nil
      expect(event.button_reply_id).to be_nil
      expect(event.button_reply_title).to be_nil
      expect(event.list_reply).to be_nil
      expect(event.list_reply_id).to be_nil
      expect(event.list_reply_title).to be_nil
      expect(event.list_reply_description).to be_nil
      expect(event.interactive_reply_id).to be_nil
      expect(event.interactive_reply_title).to be_nil
    end
  end
end
