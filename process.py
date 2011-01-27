# ---------------------------------------------------------------------------
# process.py
# Created on: 2011-01-20 15:45:10.00000
#   (generated by ArcGIS/ModelBuilder)
# Description: 
# ---------------------------------------------------------------------------

# Import arcpy module
import arcpy
import os
import subprocess

def add_joining_lines(input_lines, output_lines, max_distance):
    print "Starting add_joining_lines"
    
    points = "D:\\Data\\DunesGIS\\TempPoints.shp"

    arcpy.CreateFeatureclass_management(os.path.dirname(output_lines), os.path.basename(output_lines), "POLYLINE")

    # Convert the lines to points at each end
    arcpy.FeatureVerticesToPoints_management(input_lines,points,"BOTH_ENDS")

    # Generate the near table
    arcpy.Near_analysis(points, points, max_distance, True, True)

    # Get the SearchCursor to allow us to iterate over the points
    rows = arcpy.SearchCursor(points)

    # Also get an InsertCursor to allow us to add to the lines
    line_rows = arcpy.InsertCursor(output_lines)

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

        # Check to see that the nearest points aren't just the points at the end of this line
        if current_x == new_x or current_y == new_y:
            print "Equals"
            continue
            
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

def intersect_line_and_raster(input_lines, input_raster):
    cmd = "C:\\GME\\SEGME.exe -c isectlinerst(in=\\\"" + input_lines + "\\\", raster=\\\"" + input_raster + "\\\", prefix=\\\"RST_\\\")"
    print cmd
    output = subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()
    #os.system(cmd)


def add_and_check_joining_lines(input_lines, input_raster, distance):
    # Create the joining lines
    add_joining_lines(input_lines, "D:\TempLines.shp", distance)

    # Add fields to the lines based on the raster underneath
    intersect_line_and_raster("D:\TempLines.shp", input_raster)

    # Create a new calculated field for the difference between the mean and the min
    arcpy.AddField_management("D:\TempLines.shp", "Calc", "FLOAT")

    arcpy.CalculateField_management("D:\TempLines.shp", "Calc", "[RST_LWM]- [RST_MIN]")

    # Make the joining lines a layer so we can select from it
    arcpy.MakeFeatureLayer_management("D:\TempLines.shp", "tempLayer")

    # Construct the SQL WHERE clause to get what we want
    where_expression = arcpy.AddFieldDelimiters("tempLayer", "Calc") + " > 20"
    
    # Select based on the SQL WHERE clause we just constructed
    arcpy.SelectLayerByAttribute_management("tempLayer", "NEW_SELECTION", where_expression)

    # If we have some features selected then delete them, as they're the
    # ones we don't want
    if arcpy.GetCount_management("tempLayer") > 0:
        arcpy.DeleteFeatures_management("tempLayer")

    arcpy.Merge_management([input_lines, "D:\TempLines.shp"], "D:\AddJoinedLines_Output.shp")

print "Starting Main Processing Script"

arcpy.env.overwriteOutput = True
arcpy.env.XYTolerance = 0.5

# PARAMETERS HERE
input_file = "D:\\CrestsOutput_Maur.tif"
input_dem = "D:\\Maur_DEM_NoGeoref.tif"
joining_first = 1
joining_second = 50

# Local variables:
OrigCrestVector = "D:\\Users\\Student\\Documents\\ArcGIS\\Default.gdb\\RasterT_tif4"
MultipartCrestVectors = "D:\\Users\\Student\\Documents\\ArcGIS\\Default.gdb\\RasterT_tif4_MultipartToSing"

print "Converting Raster to Polyline"
# Process: Raster to Polyline
arcpy.RasterToPolyline_conversion(input_file, OrigCrestVector, "ZERO", "2", "SIMPLIFY", "Value")

print "Adding joining lines"
add_and_check_joining_lines(OrigCrestVector, input_dem, joining_first)

# TODO: Replace with Dissolve with Single Part?
arcpy.UnsplitLine_management(OrigCrestVector, "D:\UnsplitOutput.shp")

print "Adding joining lines"
add_and_check_joining_lines("D:\UnsplitOutput.shp", input_dem, joining_second)

arcpy.UnsplitLine_management("D:\UnsplitOutput.shp", "D:\UnsplitOutput_Final.shp")

##print "Integrate"
##arcpy.Integrate_management(MultipartCrestVectors, 1)
##
##print "Unsplit Line"
##arcpy.UnsplitLine_management(MultipartCrestVectors, "D:\UnsplitOutput.shp")
##
##
##
##arcpy.env.XYTolerance = 1
##print "Unsplit Line with XYTolerance = 1"
##arcpy.UnsplitLine_management("D:\UnsplitOutput.shp", "D:\UnsplitOutput_Final.shp")
##arcpy.env.XYTolerance = 0.5
##
##print "Adding joining lines"
##add_joining_lines("D:\UnsplitOutput_Final.shp", 10)
##
##
##arcpy.env.XYTolerance = 1
##print "Unsplit Line with XYTolerance = 1"
##arcpy.UnsplitLine_management("D:\UnsplitOutput_Final.shp", "D:\UnsplitOutput_Final_New.shp")
##arcpy.env.XYTolerance = 0.5
##
##
##print "Adding joining lines"
##add_joining_lines("D:\UnsplitOutput_Final_New.shp", 20)
##
##
##arcpy.env.XYTolerance = 2
##print "Unsplit Line with XYTolerance = 1"
##arcpy.UnsplitLine_management("D:\UnsplitOutput_Final_New.shp", "D:\UnsplitOutput_Final_New_Output.shp")
##arcpy.env.XYTolerance = 0.5
#arcpy.Snap_edit("D:\UnsplitOutput.shp", "D:\UnsplitOutput.shp END '5 Unknown'")

#arcpy.UnsplitLine_management(MultipartCrestVectors, "D:\FinalUnsplitOutput.shp")

#arcpy.TrimLine_edit("D:\FinalUnsplitOutput.shp", 5, "DELETE_SHORT")
print "Done"
