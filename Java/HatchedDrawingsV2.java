public class HatchedDrawingsV2 {

	/**
	 * When making a technical drawing on paper, one of the most laborious tasks 
	 * is filling in (or using more correct terminology, “hatching”) the interior 
	 * surfaces of the drawn elements with a line pattern. The most common 
	 * pattern, used to denote e.g. elements made of steel, consists of diagonal 
	 * lines drawn at regular intervals throughout the hatched surface, from 
	 * South-West to North-East.
	 * 
	 * The drawing in question has the shape of an axis-parallel polygon, i.e., all 
	 * its sides are North-to-South or West-to-East, lying on lines of the integer 
	 * grid. The hatching has to include the SW-to-NE diagonal of each square of 
	 * the grid.
	 * 
	 * The  task is to write a single integer to output, denoting the smallest 
	 * possible number of line segments Jack has to draw in order to perform 
	 * the hatching.
	 */
	
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		
		// Example string
		String dir = "NNWWNNWWSSSSWWNWWSSSWWSSEEEEEEEENNNNEE";
		
		// split the string into an array
		String[] dirArr = dir.split("");
		int totSize = dir.length();
		// Let hatchLines equal the total number of co-ord inputs
		int hatchLines = totSize;
		
		for (int i = 1; i < totSize; i++) {
			// every time  corner EN or NE is found take one from the number of
			// hatchLines
			String newStr = dirArr[i-1] + dirArr[i];
			if (newStr.equals("EN")) {
				hatchLines = hatchLines - 1;
			}
			if (newStr.equals("NE")) {
				hatchLines = hatchLines - 1;
			}
			// every time  corner SW or WS is found take one from the number of
			// hatchLines
			if (newStr.equals("SW")) {
				hatchLines = hatchLines - 1;
			}
			if (newStr.equals("WS")) {
				hatchLines = hatchLines - 1;
			}
		}
		
		// divide what remains by two as each hatchLine will have two co-ords
		hatchLines = hatchLines / 2;
		
		System.out.println(hatchLines);

	}

}
