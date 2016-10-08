////////////////////////////////////////////////////////////////////
// Open an image of a leaf and select the Window so
// all the imagej goodness can be sprinkled on the image's pixels
////////////////////////////////////////////////////////////////////
closeOpenWindows();
filepath=File.openDialog("Select a File");
open(filepath);
filename = File.getName(filepath);
selectWindow(filename);
selectLeafMask();
addSelectionsToROIManager();
closeOpenWindows();
open(filepath);
selectWindow(filename);
makeCalculations();

////////////////////////////////////////////////////////////////////
// function selectLeafMask()
// Figure out an outline around the leaf - in ImageJ this is called a selection - in 
// which the pixels inside the selection are part of the leaf.
// These are the pixels that will be used  to figure out the leaf’s yellow amount.
////////////////////////////////////////////////////////////////////
function selectLeafMask() {
	run("Color Threshold...");
	// Color Thresholder 2.0.0-rc-54/1.51g
	// Autogenerated macro, single images only!
	min=newArray(3);
	max=newArray(3);
	filter=newArray(3);
	a=getTitle();
	run("HSB Stack");
	run("Convert Stack to Images");
	selectWindow("Hue");
	rename("0");
	selectWindow("Saturation");
	rename("1");
	selectWindow("Brightness");
	rename("2");
	min[0]=5;
	max[0]=125;
	filter[0]="pass";
	min[1]=95;
	max[1]=255;
	filter[1]="pass";
	min[2]=0;
	max[2]=255;
	filter[2]="pass";
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  setThreshold(min[i], max[i]);
	  run("Convert to Mask");
	  if (filter[i]=="stop")  run("Invert");
	}
	imageCalculator("AND create", "0","1");
	imageCalculator("AND create", "Result of 0","2");
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  close();
	}
	selectWindow("Result of 0");
	close();
	selectWindow("Result of Result of 0");
	rename("LeafMask");
	if (isOpen("Threshold Color")) {
     	selectWindow("Threshold Color");
     	run("Close");
  	}
	// Colour Thresholding-------------
}
//
//
function addSelectionsToROIManager(){
	// Add the outline of the Leaf as a selection
	run("8-bit");
	setAutoThreshold("Default");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Create Selection");
	roiManager("Reset");// Selection 0 = Leaf Outline
	run("Analyze Particles...", "size=200-Infinity display clear add");
	indexToLargestArea = 0;
	if (nResults > 1) {
		// Keep the selection with the largest area.  This assumes the other selections were false positives.
		indexOfSelectionsToDelete = newArray(nResults-1);
		largestArea = 0;
		for (i=0;i<nResults;i++) {
			currentArea = getResult("Area",i);
			if (currentArea > largestArea) {
				largestArea = currentArea;
				indexToLargestArea = i;
			}
		}
		index = 0;
		for (i = 0;i<nResults;i++) {
			if (indexToLargestArea != i) {
				indexOfSelectionsToDelete[index++] = i;
			}
		}
		run("ROI Manager...");
		roiManager("Deselect");
		roiManager("Select",indexOfSelectionsToDelete);
		roiManager("Delete");
	}
	roiManager("Select", 0);
	roiManager("Rename", "Leaf");
	// Add the quadrants to the ROIManager
	xOrigin=newArray(2);
	yOrigin=newArray(2);
	width=newArray(2);
	length=newArray(2);
	xOrigin[0] = getResult("BX", indexToLargestArea);   //X Origin of Bounding Box
	yOrigin[0] = getResult("BY", indexToLargestArea);   //Y Origin of Bounding Box
	xCentroid = floor(getResult("X", indexToLargestArea))-xOrigin[0];  //Relative to xOrigin = leaf's bounding box
	yCentroid = floor(getResult("Y", indexToLargestArea))-yOrigin[0];  // Relative to yOrigin = leaf's bounding box
	xOrigin[1] = xOrigin[0]+ xCentroid;
	yOrigin[1] = yOrigin[0]+ yCentroid;
	width[0] = xCentroid;
	length[0] = yCentroid;
	width[1] = getResult("Width", indexToLargestArea) - width[0];  //Right Quadrants have the width/height of total width/height - centroid
	length[1] = getResult("Height",indexToLargestArea) - length[0];
	// Selections 1 - 4 = 4 rectangular quadrants
	currentSelection = 1;
	for (j=0;j<2; j++) {
		for (i=0;i<2;i++) {
			makeRectangle(xOrigin[i],yOrigin[j],width[i],length[j]);
			strCurrentSelection = "Q"+d2s(currentSelection,0);
			roiManager("add");
			roiManager("Select",currentSelection++);
			roiManager("Rename", strCurrentSelection);
		}
	}
	//now the leaf quadrants
	for (i=currentSelection;i<currentSelection+4;i++) {
		roiManager("Select",newArray(0,i-4));
		roiManager("and");
		roiManager("add");
		strCurrentLeafQuadrant = "L" + d2s(i-4,0);
		roiManager("Select",i);
		roiManager("Rename", strCurrentLeafQuadrant);
	}
}
//
//
function makeCalculations() {
	Rk = newArray(4);
	// The leaf selections are 5 - 8
	for (i=5;i<=8;i++) {
		roiManager("Select",i);
		setRGBWeights(1,0,0);
		getStatistics(area, mean, min, max, std, histogram);
		red = mean;
  		setRGBWeights(0, 1, 0);
		getStatistics(area, mean, min, max, std, histogram);
		green = mean;
		Rk[i-5] = floor(red/2) + floor(green/2);
		Rn += Rk[i-5];
	}
	print("Rn = "+Rn);
	Rdiff = newArray(6);
	counter = 0;
	for (j = 0;j<3;j++) {
		for (i = j+1;i<4;i++) {
			Rdiff[counter] = abs(Rk[j] - Rk[i]);
			RdiffTotal += Rdiff[counter];
			counter+=1;
		}
	}
	print("Rdiff = "+RdiffTotal);
}
////////////////////////////////////////////////////
// function closeOpenWindows()
// If there are any windows open showing images or dialog boxes, close them.
///////////////////////////////////////////////////
function closeOpenWindows() {
while (nImages>0) { 
   selectImage(nImages); 
   close(); 
   }
}