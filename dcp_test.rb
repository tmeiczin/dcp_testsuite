#!/usr/bin/env ruby
require_relative 'image.rb'
require_relative 'wav.rb'
require 'thor'

CHANNEL_COUNT_MAP = {"stereo" => 2, "5.1" => 6, "7.1" => 8}
CHANNEL_MAP = ["left", "right", "center", "sub", "left_surround", "right_surround", "left_center", "right_center"]
ASPECT_MAP = {"flat" => {"width" => 1998, "height" => 1080}, "scope" => {"width" => 2048, "height" => 858}}

def generate_square_wave(length_secs, peak_db, sample_rate, bit_depth)
  num_samples = (length_secs * sample_rate).to_i
  range = (2 ** bit_depth / 2)
  peak_samples = (range * Math::E ** (1/20.0 * peak_db * (Math.log(2) + Math.log(5)))) - 1
  x = 0
  output = []
  samples = ([0.5 * peak_samples] * 100) + ([-0.5 * peak_samples] * 100)
  num_samples.times do
    output << samples[x == 199 ? x = 0 : x += 1]
  end
  return output
end

def generate_images(duration, framerate, width, height)
  count = duration * framerate
  for i in 1..count
    filename = sprintf("test_%06d.tif", i)
    print "Writing #{filename}\n"
    image = ImageCreate.new(width, height, "pink")
    image.set_frame(i)
    image.write(filename)
  end
end

def generate_wavs(duration, channels, mono=true)
  peak_db = -12
  if mono == true
    for i in 0..channels-1
      filename = sprintf("%02d_%s.wav", i+1, CHANNEL_MAP[i])
      print "Writing #{filename}\n"
      wav = WavFileCreate.new(format=1, channels=1, sample_rate=48000, bit_depth=24)
      wav.audio_data << generate_square_wave(duration, peak_db, sample_rate, bit_depth)
      wav.write(filename)
      wav.close
    end
  else
    filename = sprintf("%d_channel.wav", channels)
    wav = WavFileCreate.new(format=1, channels=channels, sample_rate=48000, bit_depth=24)

    channels.times do
      wav.audio_data << generate_square_wave(duration, peak_db, sample_rate, bit_depth)
    end

    wav.write(filename)
    wav.close
  end
end

def check_images()
  image = ImageLoad.new("test.j2k", xyz=false)

  # check color
  print "Checking colors..."
  if image.validate_colors == true
    puts "\tOK"
  else
    puts "\tERROR: color mismatch"
  end
  
  # validate frame number
  print "Checking Frame is 001..."
  if image.ocr_frame == 001
    puts "\tOK"
  else
    puts "\tERROR: incorrect frame #{image.ocr_frame}"
  end
end

def check_wavs()
  # compare wav
  print "Write control wav"
  generate_wavs()

  print "Checking Wav..."
  if FileUtils.compare_file('test1.wav', 'test2.wav')
    puts "\tOK"
  else
    puts "\tERROR: wav files differ"
  end
end

class CLI < Thor
    desc "create", "Create test content"
    option :duration, :required => true, :type => :numeric, :banner => "N, Duration in seconds"
    option :framerate, :type => :numeric, :default => 24, :banner => "N, Frame Rate 24 | 25 | etc"
    option :profile, :default => "2k", :banner => "PROFILE, 2k | 4k"
    option :aspect,  :default => "scope", :banner => "ASPECT scope | flat"
    option :channels, :default => "5.1", :banner => "CHANNELS stereo | 5.1 | 7.1"
    def create()
        height = ASPECT_MAP[options[:aspect]]["height"]
        width = ASPECT_MAP[options[:aspect]]["width"]
        if options[:profile] == "4k"
            height *= 2
            width *= 2
        end
        #generate_images(options[:duration], options[:framerate], width, height)
        #generate_wavs(options[:duration], CHANNEL_COUNT_MAP[options[:channels]], mono=true)
    end

    desc "validate", "Validate a DCP created from test content"
    option :dcp, :required => true, :banner => "DCP, Path to DCP directory"
    def validate()
        puts "validate dcp"
    end
end

CLI.start(ARGV)
