''' Student Name: Catherine Boothman
    Student Number: D12127081

    Assignment 3:
    
    The Game of Life, also known as Life Game, or simply Life, is a cellular automaton (a system that has rules
    applied to cells and their neighbors in a grid) designed by John Conway, a professor of Finite Mathematics
    at Princeton University in 1970.

    Game of Life is an example of "emergent complexity" or "self-organizing systems", which studies how elaborate
    patterns and behaviors can emerge from very simple rules.

    The rules:
        1. Any live cell with fewer than two live neighbours dies, as if caused by under-population.
        2. Any live cell with two or three live neighbours lives on to the next generation.
        3. Any live cell with more than three live neighbours dies, as if by overcrowding.
        4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.   '''

# -------------------------------------------- Imported Packages --------------------------------------------
# to generate a random number need to import random
import random
# to get all possible combinations for still life
import itertools

# --------------------------------------------- End of Imports ----------------------------------------------


# --------------------------------------------- Defined Classes ---------------------------------------------

# cells class to create and work on cells placed in the grid
class cell(object):

    # when the cells are initally created there is no application of the rules,
    # it is completely random
    def __init__(self):
        self.state = random.randrange(0,4)  # increase the likely hood of a cell being dead 
        if self.state == 1:
            self.gmap = "*"
            self.stateDes = "alive"
        else:
            self.state = 0  # in case it is 2 or 3, want to make it 0
            self.gmap = "-"
            self.stateDes = "dead"
    # end of __init__()

    def __str__(self):
        return "The state of this cell is %s" %(self.stateDes)
    # end of __str__()

    def cellState(self):
        return self.gmap
    # end of cellState()

    def makeDead(self):
        self.state = 0
        self.gmap = "-"
        self.statDes = "dead"
        return self.gmap
    # end of makeDead() 

    def makeAlive(self):
        self.state = 1
        self.gmap = "*"
        self.statDes = "alive"
        return self.gmap
    # end of makeAlive

    def detCellState(self, cS, aC):
        self.state = cS
        
        # Reminder of rules:
        # 1. Dead cell with three live neighbours becomes a live cell
        if (cS == 0) & (aC == 3):
            newState = self.makeAlive()
        # 2. Live cell with two or three live neighbours stays alive
        elif (cS == 1) & (aC == 3):
            newState = self.makeAlive()
        elif (cS == 1) & (aC == 2):
            newState = self.makeAlive()
        # 3. Live cell with less than 2 or more than 3 live neighbours dies
        elif (cS == 1) & (aC > 3):
            newState = self.makeDead()
        elif (cS == 1) & (aC < 2):
            newState = self.makeDead()
        else:
            # needed for dead cells (cS = 0) with alive cells (aC) not equal to 3 
            newState = self.makeDead() 

        return newState
    # end of detCellState()
        
        
    
# End of cells class


#                       ---------------------------------------------


# Grid to hold cells, need three parameters as well as self (four in total)
class grid(object):

    # creates the instance of the grid called by the main program
    def __init__(self, rows=4, cols=4, lCells=6):
        self.rows = rows
        self.cols = cols
        self.lCells = lCells

        # create empty grid / list
        gridList = []
        
        for i in range(rows):
            # For each row, create a list that will
            # represent an entire row
            gridList.append([])

            # loop for each column
            for j in range(cols):
                # populate the empty grid with dead cells
                gridList[i].append("-")

            self.gridList = gridList
    # end of __init__() method
            
    # function to describe the class
    def __str__(self):
        return "This grid consists of %d rows and %d cols" %(self.rows, self.cols)
    # end of __str__() method

    def randPlaceLiveCells(self):
        row = self.rows
        col = self.cols
        lc = self.lCells
        gL = self.gridList
        numLive = 0

        # while the number of live cells in the grid is not equal to what it is meant to be,
        while numLive != lc:
            # loop through the grid
            for r in range(row):
                for c in range(col):

                    # if the number is less than required
                    if numLive < lc:
                        # identify a dead cell
                        if gL[r][c]  == "-":
                            # randomly generate a new cell
                            cellG = cell()
                            gL[r][c] = cellG.cellState()
                            # check to see if it's alive and if it
                            if gL[r][c] == "*":
                                # increase the number of live cells
                                numLive += 1

                    # if the number of live cells is greater than requires
                    if numLive > lc:
                        # identify an alive cell
                        if gL[r][c] == "*":
                            # randomly generate a new cell
                            cellG = cell()
                            gL[r][c] = cellG.cellState()
                            # check to see if it's dead and if it
                            if gL[r][c] == "-":
                                # decrease the number of live cells
                                numLive -= 1
    # end of randPlaceLiveCells()

    def placeCells(self, coOrdList):
        # place the cells in the grid according to specific co-ordinates given in coOrdList
        coL = coOrdList
        rows = self.rows
        cols = self.cols
        gL = self.gridList
        lc = self.lCells

        # first want to fill the grid with dead cells
        for r in range(rows):
            for c in range(cols):
                cellG = cell()
                gL[r][c] = cellG.makeDead()

        # next iterate through the co-ordinates list and place a live cell in the grid list according
        # to these co-ordinates
        for i in range(lc):
            r = coL[i][0]
            c = coL[i][1]
            gL[r][c] = cellG.makeAlive()   
    # end of placeCells()

    # method to return the grid as a usable list
    def getGrid(self):
        return self.gridList
    # end of getGrid() method

    def printGrid(self):
        gL = self.gridList
        for r in gL:
            # to print nicely join each row list into a string with a double space between each item
            print ("  ").join(r)
    # end of printGrid()

    def nextGenGrid(self):
        # easier to find the adjacent cells as part of this method and not as a seperate method
        rows = self.rows
        cols = self.cols
        gL = self.gridList

        # need a new gridList to store the next gen of cells so that the new cell status is based
        # solely on the current gen & not a mix of the two
        newGL = []

        for i in range(rows):
            # For each row, create a list that will
            # represent an entire row
            newGL.append([])

            # loop for each column
            for j in range(cols):
                # populate the empty grid with 0
                newGL[i].append(0)

        # go through each cell in the grid and look at its neighbours
        for r in range(rows):          
            for c in range(cols):
                aC = 0      # num of neighbouring alive cells

                # get state of current cell
                if gL[r][c] == "*":
                    cS = 1
                else:
                    cS = 0
                
                stptR = r - 1    # start point of rows of neighbours (stptR - start point Row)
                # some will be -1, need to neglect these cases
                if stptR < 0:
                    stptR = 0

                # some will be < than max no of rows
                enptR = r + 2    # end point of rows of neighbours (enptR - end point Row)
                if enptR > rows:
                    enptR = rows
                    
                stptC = c - 1    # start point of cols of neighbours
                # some will be -1, need to neglect these cases
                if stptC < 0:
                    stpt = 0
                    
                enptC = c + 2    # end point of cols of neighbours
                # some will be < than max no of cols
                if enptC > cols:
                    enptC = cols                             
                    
                for i in range(stptR, enptR):
                    for j in range(stptC, enptC):
                        # want to exclude cell under test, this cell has i = r AND j = c
                        if i == r:
                            testA = True
                        else:
                            testA = False   # must include this to make testA or testB have a value
                        if j == c:
                            testB = True
                        else:
                            testB = False

                        # testC is only true for the cell under test
                        testC = testA and testB
                        
                        if (gL[i][j] == "*") & (testC == False):
                            aC += 1

                # create a new cell to replace the old one
                cellG = cell()
                # determine its future state depending on the number of live / dead cells around it
                newGL[r][c] = cellG.detCellState(cS, aC)

        # update the old grid with the new grid
        self.gridList = newGL
    # end of nextGenGrid()

    def isEmptyGrid(self):
        # checks to see if grid is empty by counting the number of alive cells in the grid
        rows = self.rows
        cols = self.cols
        gL = self.gridList
        aC = 0

        for r in range(rows):
            for c in range(cols):
                if gL[r][c] == "*":
                    aC += 1
                    
        # if there are any alive cells the value for allDead is false
        if aC > 0:
            allDead = False
        else:
            allDead = True

        return allDead
    # end of isEmptyGrid()
        

# end of grid class


#                       ---------------------------------------------


# Start of game class
class game(object):
    def __init__(self):
        self.gameChoice = raw_input("Which game do you want to play? \nEnter sl to play still life or n for \
normal game:  ")
    # end of __init__()

    def __str__(self):
        gC = self.gameChoice
        if gC == "sl":
            return "Game selected is Still Life"
        else:
            return "Game seleced is normal generation view"
    # end of __str__()

    def getUserInputs(self):
        # user inputs the size of the grid to be used,
        while True:
            try:
                # named self. so the can be used in any of the class methods that need them
                self.rows = int(raw_input("Please enter an interger number of grid rows: "))
                break
            except ValueError:
                print "Oops!  That was no valid number.  Try again..."

        while True:
            try:
                self.cols = int(raw_input("Please enter an interger number of grid columns: "))
                break
            except ValueError:
                print "Oops!  That was no valid number.  Try again..."

        while True:
            try:
                self.liveCells = int(raw_input("Please enter an interger number of alive cells: "))
                break
            except ValueError:
                print "Oops!  That was no valid number.  Try again..."
    # end of getUserInputs()

    # method to decide to view another generation of cells
    def enterAgain(self):
        answer = raw_input("Do you wish to view the next generation of cells? (y or n): ")

        if answer == "y":
            goAgain = True
        else:
            goAgain = False

        return goAgain
    # end of enterAgain()

    def normalGame(self):
        print "Generation game selected"
        # get the number of rows, columns and live cells to be used
        self.getUserInputs()
        
        grid1 = grid(self.rows, self.cols, self.liveCells)
        grid1.randPlaceLiveCells()
        g1List = grid1.getGrid()
        
        print "First generation of cells:"
        grid1.printGrid()

        ''' First generation of cells in the grid have been generated and placed randomly in the grid.

            The next step in the program is to calculate a cell's state for the next generation of cells,
            which depends on the state of it's neighbouring cells.  '''

        numGens = 2
        nextGen = True
        allDead = grid1.isEmptyGrid()
        
        while (nextGen == True) & (allDead == False):
            allDead = grid1.isEmptyGrid()
            if allDead == False:
                nextGen = self.enterAgain()
                if nextGen == True:
                    grid1.nextGenGrid()
                    print "%d generation of cells:" %(numGens)
                    grid1.printGrid()    
            numGens += 1        
    # end of normalGame()

    def getCombinations(self):
        rows = self.rows
        cols = self.cols
        lc = self.liveCells

        # total number of grid cells
        totGrid = rows * cols

        # list to hold all possible combinations
        self.cellList = []

        # use itertools to get all possible combinations of position for
        # the number of live cells in the grid
        # each set of combinations is a tuple in the list
        for subset in itertools.combinations(range(totGrid), lc):
            self.cellList.append(subset)
    # end of getCombinations()

    def getCoOrds(self):
        rows = self.rows
        cols = self.cols
        cList = self.cellList
        lc = self.liveCells

        # list to hold new co-ords
        nList = []

        for i in range(len(cList)):
            nList.append([])
            for j in range(lc):
                r = cList[i][j] / cols
                c = cList[i][j] % cols
                coOrd = (r,c)

                # update cell list with new co-ords
                nList[i].append(coOrd)            

        self.cellList = nList
    # end of getCoOrds()

    def compare(self, fGrid, sGrid):
        if (fGrid != sGrid):
            stillLife = False
        else:
            stillLife = True
            
        return stillLife            
    # end of compare()
    
    def stillLifeGame(self):
        print "Still Life game selected"
        self.getUserInputs()

        # empty list to hold cell combinations
        self.getCombinations()
            
        # at this point the cells have only linear co-ords given by rows x cols
        # need to convert them back to real co-ords
        self.getCoOrds()

        # create a grid as for the normal game
        grid2 = grid(self.rows, self.cols, self.liveCells)

        # count how many still life patterns are produced
        slpat = 1
        # for each combination of possible placement of cells put them into the grid
        for row in self.cellList:
            grid2.placeCells(row)
            firstGrid = grid2.getGrid()
            grid2.nextGenGrid()
            secondGrid = grid2.getGrid()
            stillLife = self.compare(firstGrid, secondGrid)
            if stillLife == True:
                print "Still Life Pattern number %d: " %(slpat)
                grid2.printGrid()
                slpat += 1
    # end of stillLifeGame()
    
    def playGame(self):
        gC = self.gameChoice
        if gC == "sl":
            self.stillLifeGame()
        else:
            self.normalGame()
    # end of playGame()

# End of game class


# --------------------------------------------- End of Classes ----------------------------------------------


# game selection
game1 = game()
game1.playGame()

