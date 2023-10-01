class Audio < ApplicationRecord
  has_one_attached :file
  after_create :broadcast_audio

  # after create -> turbo broadcast
  def broadcast_audio
    broadcast_prepend_to(
      'audio-stream',
      target: 'audio-container',
      partial: 'audio/audio_container',
      locals: { audio: self, autoplay: true }
    )
  end
end
