import arcpy
from math import sqrt

def find_key(dict, val):
    return [k for k, v in dict.iteritems() if substract_points(v, val) < 0.1]

def substract_points(p1, p2):
    dx = abs(p1.X - p2.X)
    dy = abs(p1.Y - p2.Y)

    return sqrt(dx * dx + dy * dy)

def follow_line(row):
    global newLine
    # Do it by following the firstPoint
    get_points_from_line(row, first_points)
    print "%%%%%%%%%%%%% PRINTING"
    print len(newLine)
    first_points_line = newLine
    newLine = arcpy.Array()
    get_points_from_line(row, last_points)
    last_points_line = newLine

    for item in first_points_line:
        last_points_line.append(item)
        

    final_line_array = last_points_line

    print final_line_array

    # Add the new polyline to the list
    polyline = arcpy.Polyline(final_line_array)
    featureList.append(final_line_array)

    

def get_points_from_line(row, points_dict):
    global newLine
    oid = row.getValue(OIDField)
    print "Current OID = ", oid
    shape = row.getValue(shape_name)
    print "OID length = ", shape.length
    visited.append(oid)
    print "So far we have visited: ", visited

    
    for part in shape.getPart():
        for point in part:
            found_id = find_key(points_dict, point)
            print found_id

            if len(found_id) == 0:
                newLine.append(point)
                continue
            elif found_id[0] == oid:
                newLine.append(point)
                continue
            elif found_id[0] in visited:
                newLine.append(point)
                continue
            else:
                print "Yes: ", found_id
                print "Items in newLine = ", len(newLine)
                where = "\"" + str(OIDField) + "\" = " + str(found_id[0])
                print where
                found_object = arcpy.SearchCursor(input_lines, where)
                for item in found_object:
                    raw_input("Recursing:")
                    get_points_from_line(item, points_dict)        
        raw_input("Got to end of part:")

input_lines = "D:\\Data\\DunesGIS\\TestOverlaps.shp"
out_folder = "D:\\Data\\DunesGIS\\OutputOverlaps.shp"

featureList = []

# Get the SearchCursor
rows = arcpy.SearchCursor(input_lines)


desc = arcpy.Describe(input_lines)

OIDField = desc.OIDFieldName

shape_name = arcpy.Describe(input_lines).shapeFieldName

first_points = {}
last_points = {}

# Iterate once first of all to get all of the first and last
# points into an array
for row in rows:
    shape = row.getValue(shape_name)   

    first_points[row.getValue(OIDField)] = shape.firstPoint
    last_points[row.getValue(OIDField)] = shape.lastPoint


rows = arcpy.SearchCursor(input_lines)
visited = []
for row in rows:
    print "-----"

    
    # Create the array to hold all the points that will be put
    # together in a line (eventually)
    newLine = arcpy.Array()

    # Make sure line has one end not touching anything
    shape = row.getValue(shape_name)

    countfl = len(find_key(last_points, shape.firstPoint))
    countlf = len(find_key(first_points, shape.lastPoint))

    oid = row.getValue(OIDField)
    print "OID = ", oid

    print "COUNTS = ", countfl, countlf

    if countfl == 1 and countlf == 0:
        # Do the work!
        follow_line(row)

    

    print "Starting at next line"


print "Finished everything - about to write shapefile"
print len(featureList)
arcpy.CopyFeatures_management(featureList, "D:\AwesomeOutput2.shp")


del row
