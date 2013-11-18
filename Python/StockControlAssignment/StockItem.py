''' Author: Catherine Boothman
    Student Number: D12127081

    Parent class StockItem defined in this file '''


# -------------------------------------------------------------------------------------------------------------

from StockException import warehouseException

# -------------------------------------------------------------------------------------------------------------

class StockItem(object):

    def __init__(self, clientName = "Unknown", title = "Unknown", numOfCopies = 1, pricePerUnit = 9.99, warehouseNumber = 1, itemType = "Media"):
        self.__clientName = clientName
        self.title = title
        self.numOfCopies = numOfCopies
        self.pricePerUnit =  pricePerUnit
        self.warehouseNumber = warehouseNumber
        self.itemType = itemType

        # need to create a unique ID for each new instance of StockItem
        # where the number of copies of the new StockItem is > 1, each copy must have it's own ID
        # open .csv log file of all stock added & removed in READ ONLY mode
        # try / catch block in case file does not exist
        try:
            stockFile = open("BuyNLargeStock.csv", "rU")
        except IOError:
            # if the file does not exist set the uniqueID here
            self.uniqueID = 100100
        else:
            # get rid of header line
            headerLine = stockFile.readline()

            # read through file and get all existing unqiue ID's in a list
            idList = []         # list to hold IDs
            for line in stockFile:
                params = line.split(",")
                usedID = int(params[0])
                idList.append(usedID)
            
            # get the highest ID previously used and add one to it
            lastID = max(idList)
            self.uniqueID = lastID + 1

            # close file
            stockFile.close()

    def __str__(self):
        return "Stock item of type %s" %(itemType)

    def __add__(self, nextItem):
        totCost = (self.pricePerUnit * self.numOfCopies) + (nextItem.pricePerUnit * nextItem.numOfCopies)
        return totCost

    def __multiply__(self, nextItem):
        totCost = (self.pricePerUnit * self.numOfCopies) * (nextItem.pricePerUnit * nextItem.numOfCopies)
        return totCost

    def calcStorageCost(self):
        itemCost = self.pricePerUnit * self.numOfCopies
        storeCost = (itemCost / 100) * 5
        return storeCost

    def getUniqueID(self):
        return self.uniqueID

    def updateUniqueID(self, newID):
        self.uniqueID = newID

    def getTitle(self):
        return self.title
        




