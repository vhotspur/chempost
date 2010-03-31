%% Gap between lines of double- and triple- bonds.
bondgap := 2.5pt;
bondlen := 16pt;
bondmargin := 2pt;
bondmarginempty := 0.8pt;

%% Tells width of an image.
% @param picture img Picture in question.
% @return numeric Picture height.
%
def imgwidth(expr img) =
	xpart urcorner img - xpart llcorner img;
enddef;

%% Tells height of an image.
% @param picture img Picture in question.
% @return numeric Picture width.
%
def imgheight(expr img) =
	ypart urcorner img - ypart llcorner img;
enddef;

%% Tells intersection point of a rectangle and angled line.
% The line starts in the centre of the rectangle and goes under given angle.
% The returned point is the intersection of the line and the rectangle.
%
% @param numeric width Rectangle width.
% @param numeric height Rectangle height.
% @param numeric angle Angle of the line.
% @param pair realcenter Coordinates of the center of the rectangle.
% @return pair Intersection point.
%
def getintersection(expr width, height, angle, realcenter) =
	begingroup
		% the bounding rectangle
		path P;
		P := (0, 0) -- (width, 0) -- (width, height) -- (0, height) -- (0, 0);

		% size of the rotating line
		numeric s;
		s := width + height;

		% middle point of the rectangle
		pair M;
		M := (width/2, height/2);

		% the rotating line
		path L;
		L := M -- (M + (s, 0));
		L := L rotatedaround(M, angle);

		% find the intersection
		pair X;
		X := P intersectionpoint L;

		% return after converting to real coordinates
		X := X - M + realcenter;

		X
	endgroup
enddef;

%% Tells binding point for a text node.
% The routine is used to ensure that the bond starts at the correct
% place of the text.
%
% @param numeric param_angle Angle of the bond in question.
% @param string text_left Text left to the binded one.
% @param string text_center Text the bond shall be binded to.
% @param string text_right Text right to the binded one.
% @return pair Starting point for the bond (relative to (0,0)).
%
def getbindpoint(expr param_angle, text_left, text_center, text_right) =
	begingroup
		pair result;

		boolean empty_node;
		empty_node := (text_left = "") and (text_center = "") and (text_right = "");

		numeric angle;
		% stupid, but sufficient
		if param_angle > 360:
			angle := param_angle - 360;
		elseif param_angle < 0:
			angle := param_angle + 360;
		else:
			angle := param_angle;
		fi;

		picture img_left, img_center, img_right, img_whole;
		img_left := TEX("$" & text_left & "$");
		img_center := TEX("$" & text_center & "$");
		img_right := TEX("$" & text_right & "$");
		img_whole := TEX("$" & text_left & text_center & text_right & "$");


		numeric width_left, width_center, width_right, width_whole;
		width_left := imgwidth(img_left);
		width_center := imgwidth(img_center);
		width_right := imgwidth(img_right);
		width_whole := imgwidth(img_whole);

		numeric height_whole;
		string height_adapt;
		height_adapt := "{}_{3}";
		if empty_node:
			height_whole := imgheight(TEX("$\text{C}" & height_adapt & "$"));
		else:
			height_whole := imgheight(TEX("$" & text_left & text_center & text_right & height_adapt & "$"));
		fi;
		numeric verticalcenter;
		verticalcenter := height_whole/2;

		pair center_coords;
		center_coords := (width_left + width_center/2, verticalcenter);

		pair gaph, gapv;
		if empty_node:
			gaph := (bondmarginempty,0);
			gapv := (0,bondmarginempty);
		else:
			gaph := (bondmargin, 0);
			gapv := (0, bondmargin);
		fi;

		% First, handle special angles - pointing in the main
		% four directions.
		if angle = 0:
			result := (width_whole, verticalcenter) + gaph;
		elseif angle = 90:
			result := (width_left + width_center/2, height_whole) + gapv;
		elseif angle = 180:
			result := (0, verticalcenter) - gaph;
		elseif angle = 270:
			result := (width_left + width_center/2, 0) - gapv;
		else:
			% if we got here, it means that the angle is something
			% other than line in the 4 main directions
			% well, let's do some counting

			% First, handle special cases, when the binding is on the right
			% hemisphere and the right text is empty.
			% In such case, we make the binding look more natural.
			if ((angle < 90) or (angle > 270)) and (text_right = ""):
				result := getintersection(width_center + xpart 2gaph, height_whole + ypart 2gapv, angle, center_coords);

			% The same goes fot the left hemisphere
			elseif (angle > 90) and (angle < 270) and (text_left = ""):
				result := getintersection(width_center + xpart 2gaph, height_whole + ypart 2gapv, angle, center_coords);

			% Otherwise, the bond must be appended to the top or the
			% bottom of the box
			elseif (angle < 180):
				result := (width_left + width_center/2, height_whole) + gapv;
			else:
				result := (width_left + width_center/2, 0) - gapv;
			fi;
		fi;

		% When the node is empty, the result is the center of the image
		% no matter what the angle is.
		if empty_node:
			result := (width_whole/2, verticalcenter);
		fi;

		result
	endgroup
enddef;

%% Draws a bond.
% @param pair start_coords Starting coordinates of the bond.
% @param numeric bond_type Bond type (either 1, 2 or 3).
% @param numeric bond_len Lenght of the bond.
% @param numeric angle Bond angle.
% @return expr Coordinates of the end point.
%
def drawbond(expr start_coords, bond_type, bond_len, angle, drawit) =
	begingroup
		pair end_coords_virt;
		end_coords_virt := start_coords + (bond_len, 0);

		path bond;
		bond := start_coords -- end_coords_virt rotatedaround(start_coords, angle);

		pair result;
		result := point length bond of bond;

		% do the drawing
		picture bond_image;
		bond_image := image(
			if bond_type = 1:
				draw (0,0) -- (bond_len, 0);
			elseif bond_type = 2:
				draw (0, -bondgap/2) -- (bond_len, -bondgap/2);
				draw (0, +bondgap/2) -- (bond_len, +bondgap/2);
			elseif bond_type = 3:
				draw (0, -bondgap) -- (bond_len, -bondgap);
				draw (0,0) -- (bond_len, 0);
				draw (0, +bondgap) -- (bond_len, +bondgap);
			elseif bond_type = 4:
				draw (bondgap/2, +bondgap) -- (bond_len-bondgap/2, +bondgap);
				draw (0,0) -- (bond_len, 0);
			elseif bond_type = 5:
				draw (bondgap/2, -bondgap) -- (bond_len-bondgap/2, -bondgap);
				draw (0,0) -- (bond_len, 0);
			else:
				;
			fi;
		);

		if drawit:
			draw bond_image shifted start_coords rotatedaround(start_coords, angle);
		fi

		result
	endgroup
enddef;

%% Draws first node in the compound.
% @param pair coordinates Starting point.
% @param string nodetext Node text.
% @return pair Coordinates of the node (always returns @p coordinates).
%
def drawfirstnode(expr coordinates, nodetext) =
	begingroup
		picture the_text;
		the_text := TEX("$" & nodetext & "$");

		numeric text_width, text_height;
		text_width := imgwidth(the_text);
		text_height := imgheight(the_text);

		draw the_text shifted coordinates;

		coordinates
	endgroup
enddef;

%% Draws next node in the compound.
% @param pair prev_coords Coordinates of the previous (bonded) node.
% @param string prev_left Left part of text at previous node.
% @param string prev_center Binding part of text at previous node.
% @param string prev_right Right part of text at previous node.
% @param numeric angle Bond angle.
% @param numeric bond_type Bond type.
% @param string curr_left Left part of text at current node.
% @param string curr_center Binding part of text at current node.
% @param string curr_right Right part of text at current node.
% @return pair Coordinates of the node (could be used as @p prev_coords for next node).
%
def drawnextnode(expr prev_coords, prev_left, prev_center, prev_right, angle, bond_type, curr_left, curr_center, curr_right) =
	begingroup
		string curr_text;
		curr_text := curr_left & curr_center & curr_right;

		% binding points relative to the text
		pair prev_bindpoint, curr_bindpoint;
		prev_bindpoint := getbindpoint(angle, prev_left, prev_center, prev_right);
		curr_bindpoint := getbindpoint(180 + angle, curr_left, curr_center, curr_right);

		% real coordinates for the bond
		% real coordinates of the previous bind point
		pair prev_realbind;
		prev_realbind := prev_bindpoint + prev_coords;

		pair curr_realbind;
		curr_realbind := drawbond(prev_realbind, bond_type, bondlen, angle, true);

		% count coordinates for the current node text
		pair curr_coords;
		curr_coords := curr_realbind - curr_bindpoint;

		curr_coords := drawfirstnode(curr_coords, curr_text);

		curr_coords
	endgroup
enddef;

def drawnextnodefixeddistance(expr prev_coords, prev_left, prev_center, prev_right, angle, bond_type, curr_left, curr_center, curr_right, draw_text) =
	begingroup
		string curr_text;
		curr_text := curr_left & curr_center & curr_right;

		% binding points relative to the text
		pair prev_bindpoint, curr_bindpoint;
		prev_bindpoint := getbindpoint(angle, prev_left, prev_center, prev_right);
		curr_bindpoint := getbindpoint(180 + angle, curr_left, curr_center, curr_right);

		% real coordinates for the bond
		% real coordinates of the previous bind point
		pair prev_realbind;
		prev_realbind := prev_bindpoint + prev_coords;

		% make the bond shorter - as if the text would be drawn over it
		picture img_left, img_center;
		img_left := TEX("$" & curr_left & "$");
		img_center := TEX("$" & curr_center & "$");
		numeric width_left, width_center, height_all;
		width_left := imgwidth(img_left);
		width_center := imgwidth(img_center);
		height_all := imgheight(TEX("$\text{C}_3$"));

		pair center_coords;
		center_coords := (width_left + width_center/2, height_all/2);

		pair bond_cut_pair;
		bond_cut_pair := curr_bindpoint - center_coords;

		numeric bond_cut;
		bond_cut := sqrt(
			(xpart bond_cut_pair)*(xpart bond_cut_pair)
			+ (ypart bond_cut_pair)*(ypart bond_cut_pair)
		);

		pair curr_realbind;
		curr_realbind := drawbond(prev_realbind, bond_type, bondlen - bond_cut, angle, true);
		%curr_realbind := drawbond(prev_realbind, bond_type, bondlen, angle, false);

		% count coordinates for the current node text
		pair curr_coords;
		curr_coords := curr_realbind - curr_bindpoint;

		if draw_text:
			curr_coords := drawfirstnode(curr_coords, curr_text);
		fi;

		curr_coords
	endgroup
enddef;

def drawnextnodesimple(expr prev_coords, angle, bond_type) =
	drawnextnode(prev_coords, "", "", "", angle, bond_type, "", "", "");
enddef;

def drawbenzen(expr coords) =
	begingroup
		pair C[];
		C1 := drawfirstnode((0,0), "");
		C2 := drawnextnodesimple(C1, 60, 1);
		C3 := drawnextnodesimple(C2, 0, 4);
		C4 := drawnextnodesimple(C3, 300, 1);
		C5 := drawnextnodesimple(C4, 240, 4);
		C6 := drawnextnodesimple(C5, 180, 1);
		C0 := drawnextnodesimple(C6, 120, 4);
	endgroup
enddef;


