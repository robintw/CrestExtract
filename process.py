# ---------------------------------------------------------------------------
# process.py
# Created on: 2011-01-20 15:45:10.00000
#   (generated by ArcGIS/ModelBuilder)
# Description: 
# ---------------------------------------------------------------------------

# Import arcpy module
import arcpy

def add_joining_lines(input_lines, max_distance):
    print "Starting add_joining_lines"
    
    points = "D:\\Data\\DunesGIS\\TempPoints.shp"

    # Convert the lines to points at each end
    arcpy.FeatureVerticesToPoints_management(input_lines,points,"BOTH_ENDS")

    # Generate the near table
    arcpy.Near_analysis(points, points, max_distance, True, True)

    # Get the SearchCursor to allow us to iterate over the points
    rows = arcpy.SearchCursor(points)

    # Also get an InsertCursor to allow us to add to the lines
    line_rows = arcpy.InsertCursor(input_lines)

    # Get the shape field name
    shape_name = arcpy.Describe(points).shapeFieldName

    # For each row (that is, each line in the input dataset)
    for row in rows:
        # Get the nearest point found
        new_x = row.getValue("NEAR_X")
        new_y = row.getValue("NEAR_Y")

        # If one or other of them is not valid then continue to next iteration
        if new_x == -1 or new_y == -1:
            continue

        # Get the current X and Y values
        part = row.getValue(shape_name).getPart()
        current_x = part.X
        current_y = part.Y

        
        #print new_x, new_y, " : ", current_x, current_y

        # Add the points to a new array of points for the line
        lineArray = arcpy.Array()

        first = arcpy.Point(X=current_x, Y=current_y)
        last = arcpy.Point(X=new_x, Y=new_y)

        lineArray.add(first)
        lineArray.add(last)    

        # Insert the new line into the dataset
        feat = line_rows.newRow()
        feat.shape = lineArray
        line_rows.insertRow(feat)


    # Clean up
    del line_rows
    del rows



print "Starting Main Processing Script"
arcpy.env.overwriteOutput = True
arcpy.env.XYTolerance = 0.5

input_file = "D:\\CrestsOutput50.tif"

# Local variables:
CrestsOutput_tif = "CrestsOutput.tif"
OrigCrestVector = "D:\\Users\\Student\\Documents\\ArcGIS\\Default.gdb\\RasterT_tif4"
MultipartCrestVectors = "D:\\Users\\Student\\Documents\\ArcGIS\\Default.gdb\\RasterT_tif4_MultipartToSing"

print "Converting Raster to Polyline"
# Process: Raster to Polyline
arcpy.RasterToPolyline_conversion(input_file, OrigCrestVector, "ZERO", "2", "SIMPLIFY", "Value")

print "Multipart -> Singlepart"
# Process: Multipart To Singlepart
arcpy.MultipartToSinglepart_management(OrigCrestVector, MultipartCrestVectors)

print "Integrate"
arcpy.Integrate_management(MultipartCrestVectors, 1)

print "Unsplit Line"
arcpy.UnsplitLine_management(MultipartCrestVectors, "D:\UnsplitOutput.shp")

print "Adding joining lines"
add_joining_lines("D:\UnsplitOutput.shp", 2)

arcpy.env.XYTolerance = 1
print "Unsplit Line with XYTolerance = 1"
arcpy.UnsplitLine_management("D:\UnsplitOutput.shp", "D:\UnsplitOutput_Final.shp")
arcpy.env.XYTolerance = 0.5

print "Adding joining lines"
add_joining_lines("D:\UnsplitOutput_Final.shp", 10)


arcpy.env.XYTolerance = 1
print "Unsplit Line with XYTolerance = 1"
arcpy.UnsplitLine_management("D:\UnsplitOutput_Final.shp", "D:\UnsplitOutput_Final_New.shp")
arcpy.env.XYTolerance = 0.5


print "Adding joining lines"
add_joining_lines("D:\UnsplitOutput_Final_New.shp", 20)


arcpy.env.XYTolerance = 2
print "Unsplit Line with XYTolerance = 1"
arcpy.UnsplitLine_management("D:\UnsplitOutput_Final_New.shp", "D:\UnsplitOutput_Final_New_Output.shp")
arcpy.env.XYTolerance = 0.5
#arcpy.Snap_edit("D:\UnsplitOutput.shp", "D:\UnsplitOutput.shp END '5 Unknown'")

#arcpy.UnsplitLine_management(MultipartCrestVectors, "D:\FinalUnsplitOutput.shp")

#arcpy.TrimLine_edit("D:\FinalUnsplitOutput.shp", 5, "DELETE_SHORT")
print "Done"
