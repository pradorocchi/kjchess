//
//  Board.swift
//  kjchess
//
//  Copyright © 2017 Kristopher Johnson. All rights reserved.
//

import Foundation

/// Chess board.
///
/// Representation is an 8x8 array where each
/// element may be a `Piece` or be empty (`nil`).
public struct Board {
    public static let ranksCount = 8
    public static let filesCount = 8

    public static let minRank = 0
    public static let maxRank = ranksCount - 1

    public static let minFile = 0
    public static let maxFile = filesCount - 1

    public static let squaresCount = ranksCount * filesCount

    /// Return true if the given file index is in the range 0...7.
    public static func isValid(file: Int) -> Bool {
        return (minFile...maxFile).contains(file)
    }

    /// Return true if the given rank index is in the range 0...7.
    public static func isValid(rank: Int) -> Bool {
        return (minRank...maxRank).contains(rank)
    }

    /// Return true if given file and rank are in the range 0...7.
    public static func isValid(file: Int, rank: Int) -> Bool {
        return isValid(file: file) && isValid(rank: rank)
    }

    public static let empty
        = Board(Array(repeating: xx, count: Board.squaresCount))

    public static let newGame
        = Board([WR,  WN,  WB,  WQ,  WK,  WB,  WN,  WR,
                 WP,  WP,  WP,  WP,  WP,  WP,  WP,  WP,
                 xx,  xx,  xx,  xx,  xx,  xx,  xx,  xx, 
                 xx,  xx,  xx,  xx,  xx,  xx,  xx,  xx, 
                 xx,  xx,  xx,  xx,  xx,  xx,  xx,  xx, 
                 xx,  xx,  xx,  xx,  xx,  xx,  xx,  xx, 
                 BP,  BP,  BP,  BP,  BP,  BP,  BP,  BP,
                 BR,  BN,  BB,  BQ,  BK,  BB,  BN,  BR])

    /// The array that holds the board state.
    ///
    /// The array has 64 elements.  The first 8 are for squares
    /// a1-a8, the next 8 are for b1-b8, and so on.
    ///
    /// `squares` is not marked `public` or `private`.  It should
    /// be treated as if it's `private` to the `Board` type and
    /// its extensions, but Swift 3 doesn't provide that kind of
    /// access control specification.
    var squares: [Piece]

    public init(_ squares: [Piece]) {
        assert(squares.count == Board.squaresCount,
               "Number of squares must be 64")
        self.squares = squares
    }

    /// Return `Piece` at the specified `Location`.
    public subscript(location: Location) -> Piece {
        return squares[location.squareIndex]
    }

    /// Return `Piece` at the specified location.
    public func at(file: Int, rank: Int) -> Piece {
        return squares[rank * Board.filesCount + file]
    }

    /// Return `Piece` at the specified location if it is not empty.
    public func pieceAt(file: Int, rank: Int) -> Piece? {
        let piece = at(file: file, rank: rank)
        return piece.isEmpty ? nil : piece
    }

    /// Return `true` if specified `Location` has no piece on it.
    public func isEmpty(_ location: Location) -> Bool {
        return squares[location.squareIndex].isEmpty
    }

    /// Return `true` if specified square has no piece on it.
    public func isEmpty(file: Int, rank: Int) -> Bool {
        return at(file: file, rank: rank).isEmpty
    }

    /// Return copy of board after applying the given `Move`.
    ///
    /// This method does not validate whether the move is valid
    /// of the specified pieces exist.
    public func after(_ move: Move) -> Board {
        var newBoard = self
        newBoard.apply(move)
        return newBoard
    }

    /// Applying the given `Move` to the `Board`, modifying it.
    ///
    /// This method does not validate whether the move is valid
    /// of the specified pieces exist.
    public mutating func apply(_ move: Move) {
        switch move {

        case .move(let piece, let from, let to),
             .capture(let piece, let from, let to, _):
            squares[from.squareIndex] = xx
            squares[to.squareIndex] = piece

        case .promote(let player, let from, let to, let promoted),
             .promoteCapture(let player, let from, let to, _, let promoted):
            squares[from.squareIndex] = xx
            squares[to.squareIndex] = Piece(player, promoted)

        case .enPassantCapture(let player, let from, let to):
            let captureRank = (player == .white) ? to.rank - 1 : to.rank + 1
            let capturedPawnLocation = Location(to.file, captureRank)
            squares[from.squareIndex] = xx
            squares[capturedPawnLocation.squareIndex] = xx
            squares[to.squareIndex] = Piece(player, .pawn)

        case .castleKingside(let player):
            switch player {
            case .white:
                squares[e1.squareIndex] = xx
                squares[h1.squareIndex] = xx
                squares[f1.squareIndex] = WR
                squares[g1.squareIndex] = WK

            case .black:
                squares[e8.squareIndex] = xx
                squares[h8.squareIndex] = xx
                squares[f8.squareIndex] = BR
                squares[g8.squareIndex] = BK

            case .empty:
                assert(false)
            }


        case .castleQueenside(let player):
            switch player {
            case .white:
                squares[e1.squareIndex] = xx
                squares[a1.squareIndex] = xx
                squares[d1.squareIndex] = WR
                squares[c1.squareIndex] = WK

            case .black:
                squares[e8.squareIndex] = xx
                squares[a8.squareIndex] = xx
                squares[d8.squareIndex] = BR
                squares[c8.squareIndex] = BK

            case .empty:
                assert(false)
            }

        case .resign:
            break
        }
    }

    /// Reverse the effect of the given `Move`, restoring the `Board` to its previous state.
    ///
    /// Results are undefined if the given move was not the last one applied to the board.
    public mutating func unapply(_ move: Move) {
        switch move {

        case .move(let piece, let from, let to):
            squares[from.squareIndex] = piece
            squares[to.squareIndex] = xx

        case .capture(let piece, let from, let to, let capturedKind):
            squares[from.squareIndex] = piece
            squares[to.squareIndex] = Piece(piece.player.opponent, capturedKind)

        case .promote(let player, let from, let to, _):
            squares[from.squareIndex] = Piece(player, .pawn)
            squares[to.squareIndex] = xx

        case .promoteCapture(let player, let from, let to, let capturedKind, _):
            squares[from.squareIndex] = Piece(player, .pawn)
            squares[to.squareIndex] = Piece(player.opponent, capturedKind)

        case .enPassantCapture(let player, let from, let to):
            let captureRank = (player == .white) ? to.rank - 1 : to.rank + 1
            let capturedPawnLocation = Location(to.file, captureRank)
            squares[from.squareIndex] = Piece(player, .pawn)
            squares[capturedPawnLocation.squareIndex] = Piece(player.opponent, .pawn)
            squares[to.squareIndex] = xx

        case .castleKingside(let player):
            switch player {
            case .white:
                squares[e1.squareIndex] = WK
                squares[h1.squareIndex] = WR
                squares[f1.squareIndex] = xx
                squares[g1.squareIndex] = xx

            case .black:
                squares[e8.squareIndex] = BK
                squares[h8.squareIndex] = BR
                squares[f8.squareIndex] = xx
                squares[g8.squareIndex] = xx

            case .empty:
                assert(false)
            }

        case .castleQueenside(let player):
            switch player {
            case .white:
                squares[e1.squareIndex] = WK
                squares[a1.squareIndex] = WR
                squares[d1.squareIndex] = xx
                squares[c1.squareIndex] = xx

            case .black:
                squares[e8.squareIndex] = BK
                squares[a8.squareIndex] = BR
                squares[d8.squareIndex] = xx
                squares[c8.squareIndex] = xx

            case .empty:
                assert(false)
            }

        case .resign:
            break
        }
    }

    /// Return copy of board with the given `Piece` at the given `Location`.
    public func with(_ piece: Piece, _ location: Location) -> Board {
        var newSquares = Array(squares)
        newSquares[location.squareIndex] = piece

        return Board(newSquares)
    }

    /// Return copy of board with the given `Pieces` at the given `Locations`.
    public func with(_ pieceLocations: (Piece, Location)...) -> Board {
        var newSquares = Array(squares)

        for (piece, location) in pieceLocations {
            newSquares[location.squareIndex] = piece
        }

        return Board(newSquares)
    }

    /// Return array of (`Piece`, `Location`) tuples indicating pieces for the specified player.
    public func pieces(player: Player) -> [(Piece, Location)] {
        var result = [(Piece, Location)]()
        result.reserveCapacity(16)
        for squareIndex in 0..<squares.count {
            let piece = squares[squareIndex]
            if piece.player == player {
                result.append((piece, Location(squareIndex: squareIndex)))
            }
        }
        return result
    }

    /// Return location of the given player's king, or nil if there is no king on the board.
    ///
    /// If there is more than one king of the given color, returns the first one found.
    public func kingLocation(player: Player) -> Location? {
        let king = Piece(player, .king)
        for squareIndex in 0..<squares.count {
            let piece = squares[squareIndex]
            if piece == king {
                return Location(squareIndex: squareIndex)
            }
        }
        return nil
    }
}

// MARK:- Equatable
extension Board: Equatable {}
public func ==(lhs: Board, rhs: Board) -> Bool {
    if lhs.squares.count != rhs.squares.count {
        return false
    }

    for i in 0..<lhs.squares.count {
        if !(lhs.squares[i] == rhs.squares[i]) {
            return false
        }
    }

    return true
}
