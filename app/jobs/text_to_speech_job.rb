class TextToSpeechJob < ApplicationJob
  queue_as :default

  def perform(prompt)
    # Do something later
    response = Faraday.post('https://api.elevenlabs.io/v1/text-to-speech/tFNDLLYIRNYLCP4H25ro') do |req|
      req.headers['accept'] = 'audio/mpeg'
      req.headers['xi-api-key'] = Rails.application.credentials.xi_api_key
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        text: prompt,
        model_id: 'eleven_monolingual_v1',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.5
        }
      }.to_json
    end
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(response.body),
      filename: 'audio.mp3',
      content_type: 'audio/mpeg'
    )

    Audio.create!(prompt:, file: blob)
  end
end
