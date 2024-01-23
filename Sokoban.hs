module Sokoban where

import Prelude hiding (Left, Right)
import Data.List (sort, delete)
import System.IO (stdin, stdout, hSetEcho, hSetBuffering, BufferMode(..))

data Input = Up | Down | Left | Right deriving (Show, Eq, Ord)

type Coord = (Int, Int)

data World = World
  { wWalls, wCrates, wStorages :: [Coord]
  , wWorker :: Coord
  , wSteps :: Int
  , wMax :: Coord
  } deriving (Show)

emptyWorld :: World
emptyWorld = World
  { wWalls = []
  , wCrates = []
  , wStorages = []
  , wWorker = (0, 0)
  , wMax = (0, 0)
  , wSteps = 0
  }

add :: Coord -> Input -> Coord
add (x, y) input =
  case input of
    Up -> (x, y - 1)
    Down -> (x, y + 1)
    Left -> (x - 1, y)
    Right -> (x + 1, y)

level :: String
level =
  unlines
    [ "    #####"
    , "    #   #"
    , "    #o  #"
    , "  ###  o##"
    , "  #  o o #"
    , "### # ## #   ######"
    , "#   # ## #####  ..#"
    , "# o  o          ..#"
    , "##### ### #@##  ..#"
    , "    #     #########"
    ]

loadLevel :: String -> World
loadLevel str = foldl consume (emptyWorld {wMax = maxi}) elems
 where
  lns    = lines str
  coords = [[(x, y) | x <- [0 ..]] | y <- [0 ..]]
  elems  = concat $ zipWith zip coords lns
  maxX   = maximum . map (fst . fst) $ elems
  maxY   = maximum . map (snd . fst) $ elems
  maxi   = (maxX, maxY)
  consume wld (c, elt) =
    case elt of
      '@' -> wld {wWorker = c}
      'o' -> wld {wCrates = c : wCrates wld}
      '#' -> wld {wWalls = c : wWalls wld}
      '.' -> wld {wStorages = c : wStorages wld}
      ' ' -> wld
      _   -> error (show elt ++ "not recognized")

displayWorld :: World -> IO ()
displayWorld w = putStrLn . unlines . map (map func) $ coords
 where
  (maxX, maxY) = wMax w
  coords       = [[(x, y) | x <- [0 .. maxX]] | y <- [0 .. maxY]]
  isWorker w c = wWorker w == c
  func c =
    case () of
      () | isCrate w c && isStorage w c -> '*'
         | isWorker w c && isStorage w c -> '+'
         | isWall w c -> '#'
         | isWorker w c -> '@'
         | isCrate w c -> 'o'
         | isStorage w c -> '.'
         | otherwise -> ' '

modifyWorld :: World -> Input -> World
modifyWorld world input =
  case () of
    () | isCrate world newPos -> moveCrate world' newPos newPos'
       | otherwise -> world'
 where
  oldPos  = wWorker world
  newPos  = add oldPos input
  newPos' = add newPos input
  world'  = world {wWorker = newPos, wSteps = wSteps world + 1}
  moveCrate w old new = w {wCrates = new : delete old (wCrates world)}

isValid :: World -> Input -> Bool
isValid world input =
  case () of
    () | isWall world newPos -> False
       | isCrate world newPos -> not (isCrate world newPos') && not (isWall world newPos')
       | otherwise -> True
 where
  oldPos  = wWorker world
  newPos  = add oldPos input
  newPos' = add newPos input

getInput :: IO Input
getInput = do
  char <- getChar
  case char of
    'w' -> return Up
    'a' -> return Left
    's' -> return Down
    'd' -> return Right
    _   -> getInput

isWall :: World -> Coord -> Bool
isWall world coord = coord `elem` wWalls world

isCrate :: World -> Coord -> Bool
isCrate world coord = coord `elem` wCrates world

isStorage :: World -> Coord -> Bool
isStorage world coord = coord `elem` wStorages world

isFinished :: World -> Bool
isFinished world = sort (wCrates world) == sort (wStorages world)

main :: IO ()
main = do
  hSetEcho stdin False
  hSetBuffering stdin NoBuffering
  hSetBuffering stdout NoBuffering
  gameLoop $ loadLevel level

gameLoop :: World -> IO ()
gameLoop world = do
  displayWorld world
  input <- getInput
  let world' = if isValid world input
                 then modifyWorld world input
                 else world
  if isFinished world'
    then putStrLn "well done!"
    else gameLoop world'
