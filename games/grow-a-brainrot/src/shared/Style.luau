-- Visual style helpers: the classic brick-with-studs look.

local Style = {}

-- Plastic with studs on top. Balls/cylinders just get Plastic (studs don't show on curves).
function Style.brick(part: BasePart)
	part.Material = Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Inlet
	return part
end

return Style
