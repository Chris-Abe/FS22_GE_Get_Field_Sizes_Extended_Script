-- Author: Manuel Leithner, pics_by_abe
-- Name:getFieldSizesExtended
-- Description:Prints the field sizes of the selected AI fields group, extension: Total, field-, grassland-, framland-size
-- Icon:
-- Hide: no
local bitMapSize = 16384

local node = getSelection(0)

local total_field_size = 0
local total_grassland_size = 0

if node == 0 or getUserAttribute(node, "onCreate") ~= "FieldUtil.onCreate" then
    print("Error: Please select AI fields root!")
    return
end

local terrainNode = 0
local numChildren = getNumOfChildren(getChildAt(getRootNode(), 0))
for i = 0, numChildren - 1 do
    local t = getChildAt(getChildAt(getRootNode(), 0), i)
    if getHasClassId(t, ClassIds.TERRAIN_TRANSFORM_GROUP) then
        terrainNode = t
        break
    end
end

if terrainNode == 0 then
    print("Error: terrain not found!")
    return
end

local terrainSize = getTerrainSize(terrainNode)

function convertWorldToFieldOwnershipPosition(x, z)
    return math.floor(bitMapSize * (x + terrainSize * 0.5) / terrainSize, 5),
        math.floor(bitMapSize * (z + terrainSize * 0.5) / terrainSize, 5)
end

function pixelToHa(area)
    local pixelToSqm = terrainSize / bitMapSize
    return (area * pixelToSqm * pixelToSqm) / 10000
end

for i = 0, getNumOfChildren(node) - 1 do
    local field = getChildAt(node, i)
    if getUserAttribute(field, "fieldDimensionIndex") ~= nil then
        local sumPixel
        sumPixel = 0.000
        local dimensions = getChild(field, "fieldDimensions")
        local bitVector = createBitVectorMap("field")
        loadBitVectorMapNew(bitVector, bitMapSize, bitMapSize, 1, true)

        for j = 0, getNumOfChildren(dimensions) - 1 do
            local dimension = getChildAt(dimensions, j)
            local width = dimension
            local start = getChildAt(width, 0)
            local height = getChildAt(width, 1)
            local x, _, z = getWorldTranslation(start)
            local widthX, _, widthZ = getWorldTranslation(width)
            local heightX, _, heightZ = getWorldTranslation(height)
            local x, z = convertWorldToFieldOwnershipPosition(x, z)
            local widthX, widthZ = convertWorldToFieldOwnershipPosition(widthX, widthZ)
            local heightX, heightZ = convertWorldToFieldOwnershipPosition(heightX, heightZ)
            sumPixel = sumPixel + setBitVectorMapParallelogram(bitVector, x, z, widthX - x, widthZ - z, heightX - x, heightZ - z, 0, 1, 0)
        end

        print(string.format("Field %d (%s) : %.3f ha", i + 1, getName(field), pixelToHa(sumPixel)))
        total_field_size = total_field_size + pixelToHa(sumPixel)
        delete(bitVector)
    end

    -- get grassland sizes
    if getUserAttribute(field, "fieldGrassMission") == true then
        local sumPixelGrass = 0
        local dimensions = getChild(field, "fieldDimensions")

        local bitVector = createBitVectorMap("field")
        loadBitVectorMapNew(bitVector, bitMapSize, bitMapSize, 1, true)

        for j = 0, getNumOfChildren(dimensions) - 1 do
            local dimension = getChildAt(dimensions, j)

            local width = dimension
            local start = getChildAt(width, 0)
            local height = getChildAt(width, 1)
            local x, _, z = getWorldTranslation(start)
            local widthX, _, widthZ = getWorldTranslation(width)
            local heightX, _, heightZ = getWorldTranslation(height)
            local x, z = convertWorldToFieldOwnershipPosition(x, z)
            local widthX, widthZ = convertWorldToFieldOwnershipPosition(widthX, widthZ)
            local heightX, heightZ = convertWorldToFieldOwnershipPosition(heightX, heightZ)
            sumPixelGrass = sumPixelGrass + setBitVectorMapParallelogram(bitVector, x, z, widthX - x, widthZ - z, heightX - x, heightZ - z, 0, 1, 0)
        end

        total_grassland_size = total_grassland_size + pixelToHa(sumPixelGrass)
        delete(bitVector)
    end
end

function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

print("----------Total----------")
print(string.format("Total field size: %s ha", round(total_field_size, 3)))
print("----------Grass----------")
print(string.format("Total grassland size: %s ha", round(total_grassland_size, 3)))
print("----------Farmland----------")
print(string.format("Total farmland size: %s ha", round((total_field_size - total_grassland_size), 3)))