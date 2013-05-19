#
# Image Class
#

require 'RMagick'
require 'tesseract'
include Magick
 

class ImageCreate
  def initialize(width, height, color)
    @height = height
    @width  = width
    @color  = color

    @background = Image.new(width, height) { self.background_color = color }
    @rgb_colors = @background.pixel_color(0,0)
    @color_text = "#{@rgb_colors.red},#{@rgb_colors.green},#{@rgb_colors.blue}"
  end

  def set_frame(frame)
    text = "RGB: #{@color_text}\nFrame: #{frame}"
    frame = Image.new(1024, 256) { self.background_color = "white" }
    title = Draw.new
    title.annotate(frame, 0,0,0,0, text) {
      self.fill  = 'black'
      self.pointsize = 48
      self.font_weight = BoldWeight
      self.gravity = CenterGravity
    }
    @image = @background.composite(frame, CenterGravity, OverCompositeOp)
  end

  def write(filename)
    @image.write(filename)
  end
end

class ImageLoad
  attr_accessor :ocr_rgb_colors, :ocr_frame, :rgb_colors

  def initialize(filename, xyz=true)
    @image = ImageList.new filename
    @image = @image.quantize(4096)
    @pixel_colors = @image.pixel_color(0,0)
    if xyz == true
      @xyz_colors   = Pixels_XYZ.new(@pixel_colors.red, @pixel_colors.green, @pixel_colors.blue)
      @rgb_colors   = XYZtoRGB(@xyz_colors)
    else
      @rgb_colors   = Pixels_RGB.new(@pixel_colors.red, @pixel_colors.green, @pixel_colors.blue)
    end
    self.to_ocr()
    self.read_text()
  end

  def to_ocr()
    @e = Tesseract::Engine.new { |e| e.language  = :eng }
    @ocr = @image.quantize(256, colorspace=GRAYColorspace)
    @ocr.format = "JPEG"
  end

  def read_text()
    text = @e.text_for(@ocr).strip
    self.read_colors(text)
    @ocr_frame = /Frame:\s+(\d+)/.match(text)[1].to_i
  end

  def read_colors(string)
    colors  = /RGB:\s+(\d+),\s*(\d+),\s*(\d+)/.match(string)
    r, g, b = colors[1,3].map { |s| s.to_i }
    @ocr_rgb_colors = Pixels_RGB.new(r, g, b)
  end

  def difference(x1=0, x2=0)
    return (Rational((x1-x2), (x1+x2))/2 * 100).abs
  end

  def validate_colors()
    if difference(@rgb_colors.r, @ocr_rgb_colors.r) > (0.1)
      return false
    end
    if difference(@rgb_colors.g, @ocr_rgb_colors.g) > (0.1)
      return false
    end
    if difference(@rgb_colors.b, @ocr_rgb_colors.b) > (0.1)
      return false
    end

    return true
  end
end

class Pixels_XYZ
  attr_accessor :x, :y, :z

  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end
end

class Pixels_RGB
  attr_accessor :r, :g, :b

  def initialize(r, g, b)
    @r = r
    @g = g
    @b = b
  end
end

def XYZtoRGB(pixels)
  x = (Rational(pixels.x, 65535) ** 2.6) * Rational(52.37, 48)
  y = (Rational(pixels.y, 65535) ** 2.6) * Rational(52.37, 48)
  z = (Rational(pixels.z, 65535) ** 2.6) * Rational(52.37, 48)

  r =  3.2404542 * x + -1.5371385 * y + -0.4985314 * z
  g = -0.9692660 * x +  1.8760108 * y +  0.0415560 * z
  b =  0.0556434 * x + -0.2040259 * y +  1.0572252 * z

  r = (r ** Rational(1.0/2.2)) * 65535
  g = (g ** Rational(1.0/2.2)) * 65535
  b = (b ** Rational(1.0/2.2)) * 65535

  rgb = Pixels_RGB.new(r.to_i, g.to_i, b.to_i)

  return rgb
end

def RGBtoXYZ(pixels)
  return pixels
end
