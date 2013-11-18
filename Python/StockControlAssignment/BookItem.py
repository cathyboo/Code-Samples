''' Author: Catherine Boothman

    Student number: D12127081

    BookItem class inherits from StockItem class '''


# --------------------------------------- All imports -------------------------------------

from StockItem import *
import datetime
from StockException import *

# -----------------------------------------------------------------------------------------

class BookItem(StockItem):

    def __init__(self, paramList):
        self.paramList = paramList

        # eight item list
        self.client = str(paramList[0])
        self.title = paramList[1]
        self.author = paramList[2]
        self.datePub = paramList[3]
        self.genre = paramList[4]
        self.numOfCopies = int(paramList[5])
        self.pricePerUnit = float(paramList[6])
        self.warehouseNumber = int(paramList[7])
        self.itemType = "Book"
        StockItem.__init__(self, self.client, self.title, self.numOfCopies, self.pricePerUnit, self.warehouseNumber, self.itemType)

    def __str__(self):
        return "Stock item is a book item."

    def getDetails(self):
        uniqueID = self.getUniqueID()
        bookList = [uniqueID, self.client, self.title, self.author, self.datePub, self.genre, self.numOfCopies, self.pricePerUnit, self.warehouseNumber, self.itemType]
        return bookList

    def updateWarehouseNum(self, newWarehouseNumber):
        self.warehouseNumber = newWarehouseNumber

    def getDateReleased(self):
        # date must be in the format dd-mm-yyyy or else an exception is raised            
        try:
            datetime.datetime.strptime(self.datePub, '%d-%m-%Y')
        except ValueError:
            # the value error may be given because the date has already been re-formatted
            # have to try again with this format to check
            try:
                datetime.datetime.strptime(self.datePub, '%d/%B/%Y')
            except ValueError:
                timeNow = datetime.datetime.now().strftime("%d %B %Y, %H:%M:%S")
                # open error log file and append error message to the end
                logFile = open("errorLog.txt", "a")
                errorMessage = "%s: Error in BookItem.getDateReleased() - input date was not in the correct format.\n" %(timeNow)
                logFile.write(errorMessage)
                logFile.close()
                print "Release Date has been input in the wrong format"
        return self.datePub

    def isAPreRelease(self):
        today = datetime.date.today().strftime("%d/%B/%Y")
        datePub = self.getDateReleased()
        if datePub > today:
            return True
        else:
            return False

    def calcStorageCost(self):
        itemCost = self.pricePerUnit * self.numOfCopies
        storeCost = ((itemCost / 100) * 5) + 1
        return storeCost

    def checkDetails(self, methodName):
        # client list can only be one of three at the moment, CDWow, New Media or Books Unlimited
        if (self.client == "CDWow") or (self.client == "New Media") or (self.client == "Books Unlimited"):
            clientOK = True
        else:
            clientOK = False
        if clientOK == False:
            try:
                raise invalidClientException(methodName)
            except invalidClientException:
                self.client = "Invalid Client"
                print "Invalid client name"
        # check genre, fiction and non-fiction allowed
        if (self.genre == "Fiction") or (self.genre == "Non-Fiction"):
            genreOK = True
        else:
            genreOK = False
        if genreOK == False:
            try:
                raise invalidGenreException(methodName)
            except invalidGenreException:
                self.genre = "Invalid Genre"
                print "Invalid genre selected"
        # check valid warehouse number
                if (self.warehouseNumber > 4) or (self.warehouseNumber < 0):
                    try:
                        raise warehouseException(methodName)
                    except warehouseException:
                        self.warehouseNumber = 1
                        print "Invalid warehouse number given"

    




