package amusingSums;

import java.util.*;

/*
 * Figure out if a given number is a palindrome, i.e., a number which stays
 * the same when read from left to right or from right to left. If not, 
 * add the value of the number read from left to right and its value read 
 * from right to left, and check if the obtained sum is a palindrome. 
 * 
 * If not, repeat the process, until eventually a palindrome is obtained.
 */

public class AmusingSums {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		
		// produce a random number to determine how many sums Jack has to do 
		Random randomGenerator = new Random();
		int randomInt = randomGenerator.nextInt(100);
		
		for (int t = 1; t <= randomInt; t++) {
			// call getNumbers to perform the calculation
			int[] numArr = getNumbers();
			// print out the final palindrome and the number of times 
			// calculation was performed in order to get the number
			System.out.println(numArr[0] + " " + numArr[1]);
		}

	} // end of main method
	
	private static int[] getNumbers() {
		// get a random number between 1 and 80 on which Jack will perform the 
		// palindrome calculation	
		Random randomGenerator = new Random();
		int palInt = randomGenerator.nextInt(80);
		
		// reverse the number by calling the reverseNumber() method
		int revInt = reverseNumber(palInt);
		
		// i counts the number of iterations needed to get a palindrome
		int i = 0;
		while (palInt != revInt) {
			palInt = palInt + revInt;
			revInt = reverseNumber(palInt);			
			i++;
		}
		
		// integer array containing the orginal number and the amount of 
		// iterations needed
		int[] myIntArray = {palInt,i};
		return myIntArray;
		
	} // end of getNumbers method
	
	private static int reverseNumber(int palInt) {
		int revInt = 0;		
		while(palInt!=0){
		    revInt = revInt*10 + palInt%10;
		    palInt = palInt/10;
		}
		return revInt;
	} // end of reverseNumber method

}
