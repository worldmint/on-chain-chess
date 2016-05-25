/**
 * Chess contract
 * Stores any amount of games with two players and current state.
 * State encoding:
 *    positive numbers for white, negative numbers for black
 *    <TODO>
 */

contract Chess {
    int8[64] defaultState; // this should be constant if possible

    struct Game {
        address player1;
        address player2;
        string player1Alias;
        string player2Alias;
        address nextPlayer;
        address playerWhite; // Player that is white in this game
        address winner;
        int[64] state;
    }

    mapping (bytes32 => Game) public games;
    mapping (address => mapping (int => bytes32)) public gamesOfPlayers;
    mapping (address => int) public numberGamesOfPlayers;

    // stack of open game ids
    mapping (bytes32 => bytes32) public openGameIds;
    bytes32 public head;

    function Chess() {
        head = 'end';
        // Just a test to see some output, this should be more storage/cost efficient
        defaultState[0] = 1;
        defaultState[1] = 1;
        defaultState[0x38] = -1;
        defaultState[0x39] = -1;
    }

    event GameInitialized(bytes32 indexed gameId, address indexed player1, string player1Alias, address playerWhite);
    event GameJoined(bytes32 indexed gameId, address indexed player1, string player1Alias, address indexed player2, string player2Alias, address playerWhite);
    event GameStateChanged(bytes32 indexed gameId, int[64] state);
    event Move(bytes32 indexed gameId, bool indexed moveSuccesful);

    /**
     * Initialize a new game
     * string player1Alias: Alias of the player creating the game
     * bool playAsWhite: Pass true or false depending on if the creator will play as white
     */
    function initGame(string player1Alias, bool playAsWhite) public {
        // Generate game id based on player's addresses and current timestamp
        bytes32 gameId = sha3(msg.sender, now);

        // Initialize participants
        games[gameId].player1 = msg.sender;
        games[gameId].player1Alias = player1Alias;

        // Initialize state
        games[gameId].state = defaultState;


        if (playAsWhite) {
            // Player 1 will play as white
            games[gameId].playerWhite = msg.sender;

            // Game starts with White, so here P1
            games[gameId].nextPlayer = games[gameId].player1;
        }

        // Add game to gamesOfPlayers
        gamesOfPlayers[msg.sender][numberGamesOfPlayers[msg.sender]] = gameId;
        numberGamesOfPlayers[msg.sender]++;

        // Add to openGameIds
        openGameIds[gameId] = head;
        head = gameId;

        // Sent notification events
        GameInitialized(gameId, games[gameId].player1, player1Alias, games[gameId].playerWhite);
        GameStateChanged(gameId, games[gameId].state);
    }

    /**
     * Join an initialized game
     * bytes32 gameId: ID of the game to join
     * string player2Alias: Alias of the player that is joining
     */
    function joinGame(bytes32 gameId, string player2Alias) public {
      // Check that this game does not have a second player yet
      if (games[gameId].player2 != 0) {
        throw;
      }
            
      games[gameId].player2 = msg.sender;
      games[gameId].player2Alias = player2Alias;

      // If the other player isn't white, player2 will play as white
      if (games[gameId].playerWhite == 0) {
        games[gameId].playerWhite = msg.sender;
        // Game starts with White, so here P2  
        games[gameId].nextPlayer = games[gameId].player2;

      }

      // Add game to gamesOfPlayers
      gamesOfPlayers[msg.sender][numberGamesOfPlayers[msg.sender]] = gameId;
      numberGamesOfPlayers[msg.sender]++;
  
      // Remove from openGameIds
      if (head == gameId) {
        head = openGameIds[head];
        openGameIds[gameId] = 0;
      } else {
        for (var g = head; g != 'end' && openGameIds[g] != 'end'; g = openGameIds[g]) {
          if (openGameIds[g] == gameId) {
            openGameIds[g] = openGameIds[gameId];
            openGameIds[gameId] = 0;
            break;
          }
        }
      }

      GameJoined(gameId, games[gameId].player1, games[gameId].player1Alias, games[gameId].player2, player2Alias, games[gameId].playerWhite);
    }

    /* Move a figure */
    function move(bytes32 gameId) public {
        // Check that it is this player's turn
        if (games[gameId].nextPlayer != msg.sender) {
            throw;
        }

        // TODO: Validate move

        // TODO: Update state

        // TODO: Set nextPlayer

        // GameStateChanged(gameId, games[gameId].state);
        Move(gameId, true);
    }


    function getGameId(address player, int index) constant returns (bytes32) {
      return gamesOfPlayers[player][index];
    }
    
    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}
