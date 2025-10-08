# frozen_string_literal: true

require_relative '../lib/zap_message'

RSpec.describe ZapMessage::RateLimiter do
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  describe '.can_send?' do
    context 'when no rate limit headers have been received' do
      it 'allows sending based on local count' do
        expect(described_class.can_send?).to be true
      end
    end

    context 'when API rate limit headers indicate limit reached' do
      before do
        headers = {
          'x-app-usage' => '{"call_count": 100, "total_time": 50, "total_cputime": 30}'
        }
        described_class.update_from_headers(headers)
      end

      it 'prevents sending' do
        expect(described_class.can_send?).to be false
      end
    end

    context 'when API rate limit is under threshold' do
      before do
        headers = {
          'x-app-usage' => '{"call_count": 80, "total_time": 60, "total_cputime": 40}'
        }
        described_class.update_from_headers(headers)
      end

      it 'allows sending' do
        expect(described_class.can_send?).to be true
      end
    end

    context 'when any metric exceeds threshold' do
      before do
        headers = {
          'x-app-usage' => '{"call_count": 50, "total_time": 105, "total_cputime": 30}'
        }
        described_class.update_from_headers(headers)
      end

      it 'prevents sending' do
        expect(described_class.can_send?).to be false
      end
    end

    context 'when local message count exceeds limit' do
      before do
        allow(ZapMessage.configuration).to receive(:rate_limit).and_return(3)
        3.times { described_class.increment! }
      end

      it 'prevents sending' do
        expect(described_class.can_send?).to be false
      end
    end
  end

  describe '.update_from_headers' do
    context 'with valid x-app-usage header' do
      it 'parses and stores usage data' do
        headers = {
          'x-app-usage' => '{"call_count": 75, "total_time": 60}'
        }

        described_class.update_from_headers(headers)

        expect(described_class.app_usage['call_count']).to eq(75)
        expect(described_class.app_usage['total_time']).to eq(60)
      end
    end

    context 'with invalid JSON in header' do
      it 'handles parse errors gracefully' do
        headers = {
          'x-app-usage' => 'invalid json'
        }

        described_class.update_from_headers(headers)

        expect(described_class.app_usage).to eq({})
      end
    end

    context 'with x-business-use-case-usage header' do
      it 'parses and stores business usage data' do
        headers = {
          'x-business-use-case-usage' => '{"business-id": "123", "type": "whatsapp"}'
        }

        described_class.update_from_headers(headers)

        expect(described_class.business_usage['business-id']).to eq('123')
        expect(described_class.business_usage['type']).to eq('whatsapp')
      end
    end

    context 'with nil headers' do
      it 'handles nil gracefully' do
        headers = {
          'x-app-usage' => nil,
          'x-business-use-case-usage' => nil
        }

        described_class.update_from_headers(headers)

        expect(described_class.app_usage).to eq({})
        expect(described_class.business_usage).to eq({})
      end
    end
  end

  describe '.api_rate_limited?' do
    context 'when no usage data available' do
      it 'returns false' do
        expect(described_class.api_rate_limited?).to be false
      end
    end

    context 'when call_count is at threshold' do
      before do
        headers = { 'x-app-usage' => '{"call_count": 100}' }
        described_class.update_from_headers(headers)
      end

      it 'returns true' do
        expect(described_class.api_rate_limited?).to be true
      end
    end

    context 'when all metrics under threshold' do
      before do
        headers = { 'x-app-usage' => '{"call_count": 99, "total_time": 80}' }
        described_class.update_from_headers(headers)
      end

      it 'returns false' do
        expect(described_class.api_rate_limited?).to be false
      end
    end
  end

  describe '.increment!' do
    it 'increments message count' do
      expect { described_class.increment! }.to change { described_class.messages_sent }.by(1)
    end
  end

  describe '.messages_remaining' do
    it 'calculates remaining messages' do
      allow(ZapMessage.configuration).to receive(:rate_limit).and_return(1000)
      5.times { described_class.increment! }

      expect(described_class.messages_remaining).to eq(995)
    end

    it 'returns 0 when limit exceeded' do
      allow(ZapMessage.configuration).to receive(:rate_limit).and_return(5)
      10.times { described_class.increment! }

      expect(described_class.messages_remaining).to eq(0)
    end
  end

  describe '.reset!' do
    it 'clears all counters and usage data' do
      headers = { 'x-app-usage' => '{"call_count": 50}' }
      described_class.update_from_headers(headers)
      5.times { described_class.increment! }

      described_class.reset!

      expect(described_class.messages_sent).to eq(0)
      expect(described_class.app_usage).to eq({})
      expect(described_class.business_usage).to eq({})
    end
  end
end
