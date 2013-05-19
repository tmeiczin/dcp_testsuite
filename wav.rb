#
# WaveFile Class
#

class WavFileCreate

  HEADER_PACK_FORMAT = "A4V"
  HEADER_DATA_PACK_FORMAT = "vvVVvv"
  SAMPLE_PACK_FORMAT = "VX"
  RIFF_OFFSET  = 8
  FORMAT_OFFSET = 12

  attr_accessor :channels, :sample_rate, :bit_depth, :audio_data
  
  def initialize(format=1, channels=1, sample_rate=48000, bit_depth=24)
    @audio_format = format
    @channels     = channels
    @sample_rate  = sample_rate
    @bit_depth    = bit_depth
    @audio_data   = []
  end

  def close
    @file.close
  end

  def block_align
    channels * (@bit_depth)
  end

  def byte_rate
    sample_rate * @channels * (@bit_depth/8)
  end
  
  def pack_samples(samples)
      return samples.map { |s| [s].pack(SAMPLE_PACK_FORMAT) }.join
  end

  def pack_header_data
    [ @audio_format, @channels,
    @sample_rate, byte_rate,
    block_align, @bit_depth ].pack(HEADER_DATA_PACK_FORMAT)
  end
  
  def write(file)
    @file = File.open(file, 'w+')
    @file.binmode
    write_riff_type
    write_fmt_chunk
    write_data_chunk(@audio_data)
    write_riff_header
  end

  def write_riff_type
    @file.seek(RIFF_OFFSET)
    @file.print(["WAVE"].pack("A4"))
  end

  def write_fmt_chunk
    @file.seek(FORMAT_OFFSET)
    @file.print(["fmt ", 16].pack(HEADER_PACK_FORMAT))
    @file.print(pack_header_data)
  end
  
  def write_data_chunk(audio_data)
    data_chunk_begin = @file.tell
    @file.seek(8, IO::SEEK_CUR)
    @data_begin = @file.tell
    
    if audio_data.length > 1
      interleaved_audio_data = audio_data[0].zip(*audio_data[1..-1]).flatten
    else
      interleaved_audio_data = audio_data[0]
    end
    
    samples = interleaved_audio_data.map { |s| [s].pack("VX") }.join

    @file.print(samples)
    @data_end = @file.tell
    @file_end = @file.tell
    @file.seek(data_chunk_begin)
    @file.print(["data", @data_end - @data_begin].pack(HEADER_PACK_FORMAT))
  end

  def write_riff_header
    @file.seek(0)
    @file.print(["RIFF", @file_end].pack(HEADER_PACK_FORMAT))
  end
  
end