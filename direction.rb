require_relative 'point2d'

class North
    def right() East.new end
    def left() West.new end
    def reverse() South.new end
    def vec() Point2D.new(0,-1) end

    def reflect(mirror)
        case mirror
        when '/';   SouthWest.new
        when '\\';  SouthEast.new
        when '_';   South.new
        when '|';   North.new
        end
    end

    def ==(other) other.is_a?(North) end
    def coerce(other) return self, other end
end

class NorthEast
    def right() SouthEast.new end
    def left() NorthWest.new end
    def reverse() SouthWest.new end
    def vec() Point2D.new(1,-1) end

    def reflect(mirror)
        case mirror
        when '/';   South.new
        when '\\';  East.new
        when '_';   SouthEast.new
        when '|';   NorthWest.new
        end
    end

    def ==(other) other.is_a?(NorthEast) end
    def coerce(other) return self, other end
end

class East
    def right() South.new end
    def left() North.new end
    def reverse() West.new end
    def vec() Point2D.new(1,0) end

    def reflect(mirror)
        case mirror
        when '/';   SouthEast.new
        when '\\';  NorthEast.new
        when '_';   East.new
        when '|';   West.new
        end
    end

    def ==(other) other.is_a?(East) end
    def coerce(other) return self, other end
end

class SouthEast
    def right() SouthWest.new end
    def left() NorthEast.new end
    def reverse() NorthWest.new end
    def vec() Point2D.new(1,1) end

    def reflect(mirror)
        case mirror
        when '/';   East.new
        when '\\';  North.new
        when '_';   NorthEast.new
        when '|';   SouthWest.new
        end
    end
    
    def ==(other) other.is_a?(SouthEast) end
    def coerce(other) return self, other end
end

class South
    def right() West.new end
    def left() East.new end
    def reverse() North.new end
    def vec() Point2D.new(0,1) end

    def reflect(mirror)
        case mirror
        when '/';   NorthEast.new
        when '\\';  NorthWest.new
        when '_';   North.new
        when '|';   South.new
        end
    end

    def ==(other) other.is_a?(South) end
    def coerce(other) return self, other end
end

class SouthWest
    def right() NorthWest.new end
    def left() SouthEast.new end
    def reverse() NorthEast.new end
    def vec() Point2D.new(-1,1) end

    def reflect(mirror)
        case mirror
        when '/';   North.new
        when '\\';  West.new
        when '_';   NorthWest.new
        when '|';   SouthEast.new
        end
    end
    
    def ==(other) other.is_a?(SouthWest) end
    def coerce(other) return self, other end
end

class West
    def right() North.new end
    def left() South.new end
    def reverse() East.new end
    def vec() Point2D.new(-1,0) end

    def reflect(mirror)
        case mirror
        when '/';   NorthWest.new
        when '\\';  SouthWest.new
        when '_';   West.new
        when '|';   East.new
        end
    end

    def ==(other) other.is_a?(West) end
    def coerce(other) return self, other end
end

class NorthWest
    def right() NorthEast.new end
    def left() SouthWest.new end
    def reverse() SouthEast.new end
    def vec() Point2D.new(-1,-1) end

    def reflect(mirror)
        case mirror
        when '/';   West.new
        when '\\';  South.new
        when '_';   SouthWest.new
        when '|';   NorthEast.new
        end
    end
    
    def ==(other) other.is_a?(NorthWest) end
    def coerce(other) return self, other end
end
