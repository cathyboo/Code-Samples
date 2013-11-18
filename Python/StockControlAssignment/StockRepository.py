''' Author: Catherine Boothman

    Student Number: D12127081 '''


# -------------------------------------------------------------------------------------------------------------

from BookItem import *
from CDItem import *
from StockException import stockItemAddedException
from StockException import warehouseException
from StockException import stockExsitsException

# -------------------------------------------------------------------------------------------------------------

class StockRepository(StockItem):

    def __init__(self):
        self.stockCollection = "BuyNLargeStock.csv"

    def getMaxUniqueID(self):
        try:
            stockFile = open(self.stockCollection, "rU")
        except IOError:
            return 100099
        else:
            # get rid of header line
            headerLine = stockFile.readline()
            # read through file and get all existing unqiue ID's in a list
            idList = []         # list to hold IDs
            for line in stockFile:
                params = line.split(",")
                usedID = int(params[0])
                idList.append(usedID)
            # get the highest ID
            maxID = max(idList)
            stockFile.close
            return maxID

    def enterStock(self, stockItem):
        # want to make sure all details of the stock item are valid, code here give defaults and/or error messages for invalid values
        stockItem.checkDetails("StockRepository.enterStock()")
        itemList = stockItem.getDetails()
        stockID = int(itemList[0])
        stockName = itemList[2]
        # have to make each paramater in the itemList a string and add it to a string list
        itemStringList = []
        for item in itemList:
            itemStringList.append(str(item))
        itemString = ",".join(itemStringList)
        # open stock inventory to read
        try:
            stockFile = open(self.stockCollection, "rU")
        except IOError:
            # if the file does not exist create it
            headerLine = "UniqueID,Client,Title,Creator,Date,Genre,NumberOfCopies,Price,Warehouse,ItemType,Flag\n"
            itemString = "%s,added\n" %(itemString)
            stockFile = open(self.stockCollection, "a")
            stockFile.write(headerLine)
            stockFile.write(itemString)
            stockFile.close()
        else:
            # get rid of header line
            headerLine = stockFile.readline()
            # read through file and get all existing unqiue ID's and titles
            stockAdded = False
            for line in stockFile:
                params = line.split(",")
                uniqueID = int(params[0])
                name = params[2]
                if (stockID == uniqueID) and (stockName != name):
                    # unique ID has been used because a series of items were created using a for loop
                    # but they were no added to file, need to change the ID of the stockItem
                    # close file in order to open it for reading
                    maxID = self.getMaxUniqueID()
                    stockID = maxID + 1
                    stockItem.updateUniqueID(stockID)
                if (stockID == uniqueID) and (stockName == name):
                    # item has already been added to stock
                    stockAdded = True
            # file was opened in read mode so now it has to be closed
            stockFile.close()
            # item has been checked and updated as necassary
            if stockAdded == True:
                try:
                    raise stockItemAddedException("StockRepository.enterStock()")
                except stockItemAddedException:
                    print "Stock item already added to stock collection."
            else:
                itemList = stockItem.getDetails()
                # have to make each paramater in the itemList a string and add it to a string list
                itemStringList = []
                for item in itemList:
                    itemStringList.append(str(item))
                itemString = ",".join(itemStringList)
                itemString = "%s,added\n" %(itemString)
                # open file to append
                stockFile = open(self.stockCollection, "a")
                stockFile.write(itemString)
                stockFile.close()

    def checkStockAdded(self, stockItem):
        stockID =  stockItem.getUniqueID()
        # open file to read
        stockFile = open(self.stockCollection, "rU")
        # get rid of header line
        headerLine = stockFile.readline()
        stockExsits = False
        for line in stockFile:
            line = line.strip("\n")
            params = line.split(",")
            if (stockID == int(params[0])) and (params[10] != "deleted"):
                stockExists = True
            elif (stockID == int(params[0])) and (params[10] == "deleted"):
                stockExists = False
        return stockExists
        

    def moveStock(self, stockItem, newWarehouseNumber):        
        if (newWarehouseNumber < 0) or (newWarehouseNumber > 4):
            try:
                raise warehouseException("StockRepositiory.moveStock()")
            except warehouseException:
                newWarehouseNumber = 2
                print "Warehouse number outside valid range"
        else:
            # open stock file in append mode
            stockItem.updateWarehouseNum(newWarehouseNumber)
            itemList = stockItem.getDetails()
            # have to make each paramater in the itemList a string and add it to a string list
            itemStringList = []
            for item in itemList:
                itemStringList.append(str(item))
            itemString = ",".join(itemStringList)
            itemString = "%s,moved\n" %(itemString)
            # open file to append
            stockFile = open(self.stockCollection, "a")
            stockFile.write(itemString)
            stockFile.close()     

    def deleteStock(self, stockItem):
        # stock must exist in Buy 'N Large database before it can be deleted
        stockAdded = self.checkStockAdded(stockItem)
        if stockAdded == False:
            try:
                raise stockExsitsException("StockRepository.deleteStock()")
            except stockExsitsException:
                print "Stock item has not been added or has already been deleted from the database"
        else:
            # open stock file in append mode
            itemList = stockItem.getDetails()
            # have to make each paramater in the itemList a string and add it to a string list
            itemStringList = []
            for item in itemList:
                itemStringList.append(str(item))
            itemString = ",".join(itemStringList)
            itemString = "%s,deleted\n" %(itemString)
            # open file to append
            stockFile = open(self.stockCollection, "a")
            stockFile.write(itemString)
            stockFile.close()

    def addAllStockInWarehouse(self, warehouseNum):
        # open file to read
        stockFile = open(self.stockCollection, "rU")
        # get rid of header line
        headerLine = stockFile.readline()
        # list to hold all items in a warehouse
        whItemList = []
        # read through file
        for line in stockFile:
            line = line.strip("\n")
            params = line.split(",")
            if int(params[8]) == warehouseNum and (params[10] != "deleted"):
                itemID = params[0]
                itemAmount = params[6]
                itemFlag = params[10]
                whItemTup = (itemID, itemAmount, itemFlag)
                whItemList.append(whItemTup)
        stockFile.close()
        # check to make sure any added item hasn't been moved or deleted from the warehouse
        count = 0
        for tup in whItemList:
            tupID = int(whItemList[count][0])
            tupAmount = int(whItemList[count][1])
            tupFlag = whItemList[count][2]
            stockFile = open(self.stockCollection, "rU")
            headerLine = stockFile.readline()
            for line in stockFile:
                line = line.strip("\n")
                params = line.split(",")
                if (tupID == int(params[0])) and (params[10] == "moved") and (tupFlag == "added") and (warehouseNum != int(params[8])):
                    # item has been since moved to another warehouse so delete it from the warehouse item list
                    del whItemList[count]
                elif tupID == int(params[0]) and ((tupFlag == "added") or (tupFlag == "moved")) and (params[10] == "deleted"):
                    # item was deleted from the warehouse after being added or moved there so delete it from warehouse item list
                    del whItemList[count]
            stockFile.close()
            count += 1
        # go through final list and add up stock items
        warehouseStock = 0
        for tup in whItemList:
            tupAmount = int(tup[1])
            warehouseStock = warehouseStock + tupAmount
        return warehouseStock
