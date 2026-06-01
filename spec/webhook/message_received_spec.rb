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

  describe 'BSUID and username accessors' do
    let(:message) do
      {
        'from' => '5511999999999',
        'from_user_id' => 'BR.99887766554433221100',
        'parent_user_id' => 'BR.ENT.11223344556677889900',
        'id' => 'wamid.bsuid1',
        'timestamp' => '1609459200',
        'type' => 'text',
        'text' => { 'body' => 'Hello' }
      }
    end
    let(:contacts) do
      [{
        'profile' => { 'name' => 'John Doe', 'username' => 'johnd' },
        'wa_id' => '5511999999999',
        'user_id' => 'BR.99887766554433221100'
      }]
    end
    let(:event) { described_class.new(message: message, contacts: contacts, metadata: metadata) }

    it 'exposes the message-level BSUID' do
      expect(event.from_user_id).to eq('BR.99887766554433221100')
      expect(event.sender_bsuid).to eq('BR.99887766554433221100')
    end

    it 'exposes the parent BSUID' do
      expect(event.parent_user_id).to eq('BR.ENT.11223344556677889900')
    end

    it 'exposes the contacts-block BSUID and username' do
      expect(event.sender_user_id).to eq('BR.99887766554433221100')
      expect(event.sender_username).to eq('johnd')
    end

    it 'prefers the BSUID for sender_identifier' do
      expect(event.sender_identifier).to eq('BR.99887766554433221100')
    end

    context 'when the user has adopted a username (no phone number)' do
      let(:message) do
        {
          'from_user_id' => 'BR.99887766554433221100',
          'id' => 'wamid.bsuid2',
          'type' => 'text',
          'text' => { 'body' => 'Hi' }
        }
      end
      let(:contacts) do
        [{ 'profile' => { 'name' => 'Jane', 'username' => 'janed' }, 'user_id' => 'BR.99887766554433221100' }]
      end

      it 'falls back to the BSUID for sender_identifier when phone is absent' do
        expect(event.from).to be_nil
        expect(event.sender_wa_id).to be_nil
        expect(event.sender_identifier).to eq('BR.99887766554433221100')
      end
    end
  end
end
