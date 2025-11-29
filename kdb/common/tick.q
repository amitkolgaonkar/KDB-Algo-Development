//tick.q - ticker plant with your schema
//File: kdb/common/tick.q
\l schema.q

.tickSubscribers:() //list of connected subscribers
/ ======================= handleData Function ==========================
/ handleData is called by feeder (e.g., kdb('handleData', msg_dict))
handleData:{[msg]
    table: msg`table;
    data: msg`data;
    / validation check
    if[not table in tbls;
        show "ERROR: Unknown table: ", string table;
        :();
    ];
    / append data to the table
    / example: underlying, option_chain, nifty_opts, etc.
    switch table {
        `option_chain: option_chain insert data;
        `nifty_opts: nifty_opts insert data;
        `pnl: pnl insert data;
        `strategy_state: strategy_state insert data;
        `signals: signals insert data;
        : show "Unknown table type: ", string table;
    };
};



//Function to subscribe to tick data
subscribe:{[func]
    .tickSubscribers,:func
}
//Function to broadcast data to subscribers
broadcastData:{[table; data]
    foreach[{[sub]
        sub[table; data]
    };  .tickSubscribers]
}
//Function to handle incoming connections
handleConnection:{[conn]
//Handle incoming data from feeeder
while[1;
    try:{
        msg:read0 conn;
        if[not null msg;
            handleData[msg];
            //Broadcast to subscribers
            if[msg `table in `option_chain`nifty_opts;
                broadcastData[msg `table; msg `data]
            ];

        ];
    }catch{
        close conn;
        break;
    };

];

}
//Main server Loop
/ ======================= Server Loop (hlisten for Feeder Connections) ==========================
/ Start listening on port for feeder connections
server:{[port]
    h: hlisten port;  / Listen on port
    show "Tickerplant listening on port ", string port;
    while[1;
        conn: first h;  / Accept connection
        if[not null conn;
            / Read msg from connection
            msg: hread conn;  / Read dict from feeder
            if[not null msg;
                handleData msg;  / Call handleData
            ];
            / Close on error or end
            close conn;
        ];
    ];
};


//Initialie ticker Plant
initialize:{
    `$"Ticker Plant initialized with schema";
    //Start Listening for connections
    server 5000;
}
//Start the ticker Plant
initialize[]