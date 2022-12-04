//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./verifier.sol";
import "./poseidon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Mastermind is Verifier,Ownable{
    uint8 public MAX_ROUND = 0;
    uint8 public currentRound = 1;
    uint256 public wagerAmount=0;
    address[2] public players;
    address public winner;
    mapping(address => uint256) public solutionHashes;

    //Highlighting the several stages in the game
    enum Stages {
        Register,
        CommitSolutionHash,
        Playing,
        Reveal
    }
    //initialize first stage
    Stages public stage = Stages.Register;

    modifier atStage(Stages _stage) {
        require(stage == _stage, "not allowed!");
        _;
    }

    struct Guess {
        uint8 one;
        uint8 two;
        uint8 three;
        uint8 four;
        bool submitted;
    }

    struct HB {
        uint8 hit;
        uint8 blow;
        bool submitted;
    }

    //store players' guesses and hitblow value for each round
    mapping(address => Guess)[100] public submittedGuess;
    mapping(address => HB)[100] public submittedHB;

    //emit event whenever a guess is submitted
    event SubmitGuess(
        address indexed player,
        uint8 currentRound,
        uint8 a,
        uint8 b,
        uint8 c,
        uint8 d
    );
    //emit event when a hitblow is submitted
    event SubmitHB(
        address indexed player,
        uint8 currentRound,
        uint8 hit,
        uint8 blow
    );

    event StageChange(Stages stage);
    event RoundChange(uint8 round);
    event Register(address indexed player);
    event CommitSolutionHash(address indexed player, uint256 solutionHash);

    event Reveal(address indexed player, uint8 a, uint8 b, uint8 c, uint8 d);
    event GameFinish(address indexed winner);
    event Initialize();

    constructor(uint256 _wagerAmount,uint8 _MAX_ROUND){
        //minimum value to be deposited is 10 Matic
        require(_wagerAmount>1 ether);
        require(_MAX_ROUND<100);
        require(_MAX_ROUND>5);
        wagerAmount=_wagerAmount;
        MAX_ROUND=_MAX_ROUND;
    }

    
    //clear all data and reset game
    function initializeOnlyOwner() public onlyOwner {
        initGameState();
    }

    function initialize() public {
        require(
            msg.sender == players[0] || msg.sender == players[1],
            "not allowed"
        );
        initGameState();
    }

    function initGameState() private {
        stage = Stages.Register;
        currentRound = 1;
        // looking for better way...
        for (uint8 i = 0; i < MAX_ROUND; i++) {
            delete submittedGuess[i][players[0]];
            delete submittedGuess[i][players[1]];
            delete submittedHB[i][players[0]];
            delete submittedHB[i][players[1]];
        }
        solutionHashes[players[0]] = 0;
        solutionHashes[players[1]] = 0;
        players[0] = address(0);
        players[1] = address(0);
        winner = address(0);
        emit Initialize();
    }

    function getplayers() public view returns (address[2] memory) {
        return players;
    }

     function getSubmittedGuesses(address player)
        public
        view
        returns (Guess[] memory)
    {
        Guess[] memory guessArray = new Guess[](currentRound);

        for (uint8 i = 0; i < currentRound; i++) {
            guessArray[i] = submittedGuess[i][player];
        }
        return guessArray;
    }

    function getSubmittedHB(address player) public view returns (HB[] memory) {
        HB[] memory hbArray = new HB[](currentRound);

        for (uint8 i = 0; i < currentRound; i++) {
            hbArray[i] = submittedHB[i][player];
        }
        return hbArray;
    }

    function getOpponentAddr() private view returns (address) {
        if (players[0] == msg.sender) {
            return players[1];
        } else {
            return players[0];
        }
    }

    function register() payable public atStage(Stages.Register) {
        if (players[0] == address(0)) {
            require(msg.value==wagerAmount);
            players[0] = msg.sender;
            emit Register(msg.sender);
        } else {
            require(players[0] != msg.sender, "already registerd!");
            require(msg.value==wagerAmount);
            players[1] = msg.sender;
            stage = Stages.CommitSolutionHash;
            emit Register(msg.sender);
            emit StageChange(Stages.CommitSolutionHash);
        }
    }

    function commitSolutionHash(uint256 solutionHash)
        public
        atStage(Stages.CommitSolutionHash)
    {
        solutionHashes[msg.sender] = solutionHash;
        emit CommitSolutionHash(msg.sender, solutionHash);

        if (solutionHashes[getOpponentAddr()] != 0) {
            stage = Stages.Playing;
            emit StageChange(Stages.Playing);
        }
    }

    function submitGuess(
        uint8 guess1,
        uint8 guess2,
        uint8 guess3,
        uint8 guess4
    ) public atStage(Stages.Playing) {
        require(
            submittedGuess[currentRound - 1][msg.sender].submitted == false,
            "already submitted!"
        );

        Guess memory guess = Guess(guess1, guess2, guess3, guess4, true);
        submittedGuess[currentRound - 1][msg.sender] = guess;

        emit SubmitGuess(
            msg.sender,
            currentRound,
            guess1,
            guess2,
            guess3,
            guess4
        );
    }

    function submitHbProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) public atStage(Stages.Playing) {
        require(
            verifyProof(a, b, c, input),
            "Invalid proof submitted"
        );
        uint8 hit = uint8(input[5]);
        uint8 blow = uint8(input[6]);
        HB memory hb = HB(hit, blow, true);
        submittedHB[currentRound - 1][msg.sender] = hb;

        bool isDraw = false;
        if (hit == 4) {
            if (winner != address(0)) {
                isDraw = true;
                winner = address(0);
            } else {
                winner = getOpponentAddr();
            }
        }

        address opponentAddr = getOpponentAddr();
        if (isDraw) {
            emit GameFinish(winner);
            initGameState();
        } else if (
            submittedHB[currentRound - 1][opponentAddr].submitted == true
        ) {
            if (winner != address(0)) {
                emit GameFinish(winner);
                stage = Stages.Reveal;
                emit StageChange(Stages.Reveal);
            } else {
                currentRound++;
                emit RoundChange(currentRound);
            }
        }

        emit SubmitHB(msg.sender, currentRound, hit, blow);
    }


    function reveal(
        uint256 salt,
        uint8 a,
        uint8 b,
        uint8 c,
        uint8 d
    ) public atStage(Stages.Reveal) {
        // Confirm that the correct hash was provided
        require(
            PoseidonT6.poseidon([salt, a, b, c, d]) == solutionHashes[msg.sender],
            "Hash not correct"
        );

        emit Reveal(msg.sender, a, b, c, d);
        address payable _winner = payable(winner);
        if(_winner!=address(0)){
            _winner.transfer(wagerAmount*2);
        }else{
            payable(players[0]).transfer(wagerAmount);
            payable(players[1]).transfer(wagerAmount);
        }
        emit GameFinish(_winner);
    }

}