# frozen_string_literal: true

# Stubs Net::HTTP#request for API specs. Records every request sent and answers
# with the queued responses in order (the last one repeats).
#
#   stub_http(status: 200, body: { 'messages' => [{ 'id' => 'wamid.1' }] })
#   ...
#   expect(http_requests.last.path).to end_with('/marketing_messages')
module HttpStub
  def stub_http(*responses)
    responses = [{ status: 200, body: {} }] if responses.empty?
    queue = responses.map { |response| build_http_response(**response) }

    allow_any_instance_of(Net::HTTP).to receive(:request) do |_http, request|
      http_requests << request
      queue.size > 1 ? queue.shift : queue.first
    end
  end

  def http_requests
    @http_requests ||= []
  end

  def request_body(request = http_requests.last)
    JSON.parse(request.body)
  end

  private

  def build_http_response(status:, body:)
    klass = Net::HTTPResponse::CODE_TO_OBJ[status.to_s]
    response = klass.new('1.1', status.to_s, '')
    allow(response).to receive(:body).and_return(body.to_json)
    response
  end
end

RSpec.configure do |config|
  config.include HttpStub
end
