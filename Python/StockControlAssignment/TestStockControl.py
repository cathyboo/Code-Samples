''' Author: Catherine Boothman

    Student Number: D12127081 '''


# -------------------------------------------------------------------------------------------------------------

from BookItem import *
from CDItem import *
from StockRepository import *
import unittest
import random

# -------------------------------------------------------------------------------------------------------------

class testStockControl(unittest.TestCase):

    def setUp(self):
        cdParamList1 = ["CDWow", "At War with the Mystics", "Flaming Lips", "03-04-2006", "Rock", 7, 8.99, 3]
        cdParamList2 = ["CDWow", "One Kind Favor", "B.B. King", "26-08-2008", "Blues", 10, 9.99, 1]
        cdParamList3 = ["New Media Two", "The Black Album", "Metalica", "12-08-1991", "Metal", 5, 12.99, 2]
        cdParamList4 = ["New Media", "Nevermind", "Nirvana", "24-09-1991", "Rock", 7, 9.99, 4]
        cdParamList5 = ["CDWow", "Music for the Jilted Generation", "The Prodigy", "04-July-2015", "Dance", 7, 8.99, 3]

        bookParamList1 = ["Books Unlimited", "The Lion the Witch and the Wardrobe", "C.S. Lewis", "16-10-1950", "Fiction", 7, 7.99, 1]
        bookParamList2 = ["New Media", "A Short History Of Nearly Everything", "Bill Byrson", "31-07-2003", "Non-Fiction", 3, 15.99, 2]
        bookParamList3 = ["Books Unlimited", "The Book Thief", "Markus Zusak", "14-03-2006", "Fiction", 8, 10.99, 7]
        bookParamList4 = ["New Media", "Fermat's Last Therom", "Simon Singh", "22-06-1997", "Non-Fiction", 9, 9.99, 4]
        bookParamList5 = ["Books Unlimited", "The Curious Incident of the Dog in the Night-time", "M. Haddon", "15-05-2003", "Fiction", 6, 8.99, 3]

        self.cd1 = CDItem(cdParamList1)
        self.cd2 = CDItem(cdParamList2)
        self.cd3 = CDItem(cdParamList3)
        self.cd4 = CDItem(cdParamList4)
        self.cd5 = CDItem(cdParamList5)

        self.book1 = BookItem(bookParamList1)
        self.book2 = BookItem(bookParamList2)
        self.book3 = BookItem(bookParamList3)
        self.book4 = BookItem(bookParamList4)
        self.book5 = BookItem(bookParamList5)

        # store all these stock items in list to make it easier to run commands over them
        self.stockItemList = [self.cd1, self.cd2, self.cd3, self.cd4, self.cd5, self.book1, self.book2, self.book3, self.book4, self.book5]

    def testGetDateReleased(self):
        ''' test to get the release date of all stock items and to check what happens if the date is in the wrong format '''
        for item in self.stockItemList:
            date = item.getDateReleased()
            print date

    def testIsAPreRelease(self):
        ''' test to check that the isAPreRelease() method works properly '''
        for item in self.stockItemList:
            isAPreRel = item.isAPreRelease()
            name = item.getTitle()
            if isAPreRel == False:
                print "%s is not a pre-release" %(name)
            else:
                print "%s is a pre-release" %(name)

    def testItemAddition(self):
        ''' test to different types of addition - adding two stock items and adding all stock items '''
        count = 0
        runTot = float(0)
        for item in self.stockItemList:
            if count > 1:
                sumCost = self.stockItemList[count-1] + item
                print sumCost            
            runTot = (item.pricePerUnit * item.numOfCopies) + runTot 
            count += 1
        print "Total for all stock items %.2f" %(runTot)

    def testEnterStock(self):
        ''' test to enter stockItem into Buy 'N Large database (in this case .csv file)
            re-enter the stock to test what happens if the stock has already been entered '''
        for item in self.stockItemList:
            # due to the way the itemID is assigned at this point all items have the same itemID
            # this has to be changed before they are written to the file
            manageStockItem = StockRepository()
            manageStockItem.enterStock(item)   
            # want the cost of storing each item
            storeCost = item.calcStorageCost()
            print storeCost
        # do it again to check stock can only be added once
        for item in self.stockItemList:
            # due to the way the itemID is assigned at this point all items have the same itemID
            # this has to be changed before they are written to the file
            manageStockItem = StockRepository()
            manageStockItem.enterStock(item)  

    def testMoveStock(self):
        for item in self.stockItemList:
            # random new warehouse number including one outside warehouse number range
            newWarehouseNum = random.randrange(1,6)            
            manageStockItem = StockRepository()
            # item must be added to the stock list before the warehouse number can be moved
            manageStockItem.enterStock(item)
            manageStockItem.moveStock(item, newWarehouseNum)

    def testDeleteStock(self):
        for item in self.stockItemList:          
            manageStockItem = StockRepository()
            # item must be added to the stock list before it can be deleted
            manageStockItem.enterStock(item)
            manageStockItem.deleteStock(item)
        # do it again to check stock can only be deleted once
        for item in self.stockItemList:
            manageStockItem = StockRepository()
            manageStockItem.deleteStock(item)

    def testAddAllStockInWarehouse(self):
        for item in self.stockItemList:          
            manageStockItem = StockRepository()
            # item must be added to the stock list before it can be added
            manageStockItem.enterStock(item)
        warehouseNum = random.randrange(1,5)
        stockAmount = manageStockItem.addAllStockInWarehouse(warehouseNum)
        print "Total amount of stock in warehouse %d is %d" %(warehouseNum, stockAmount)


# -------------------------------------------------------------------------------------------------------------


if __name__ == "__main__":
   
    #unittest.main()
    suite = unittest.TestLoader().loadTestsFromTestCase(testStockControl)
    unittest.TextTestRunner(verbosity=2).run(suite)








