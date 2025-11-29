//tick.q - ticker plant with your schema
//File: kdb/common/tick.q
\l schema.q

.tickSubscribers:() //list of connected subscribers

// Function to handle incoming data
handleData:{[msg]
table: msg`table
data: msg`data

//validate data against schema
if[not table in key tables;
    `$"Unknown table: ",string table;
    return
];
//Store in appropriate table
case[table] of
    `option_chain: .option_chain,:data;
    `nifty_opts: .nifty_opts,:data;
    `pnl: .pnl,:data;
    `strategy_state: .strategy_state,:data;
    `signals: .signals,:data;
    :`$"Unknown table type: ",string table

}
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
server:{[port]
    h:hopen port;
    `$"Ticker Plant Started on port ",string port;
    while[1;
        try:{
            conn: haccept h;
            handleConnection [conn];
        }catch{
            `$"Error in server loop: ",string x;
        };
    ];
}
//Initialie ticker Plant
initialize:{
    `$"Ticker Plant initialized with schema";
    //Start Listening for connections
    server 5000;
}
//Start the ticker Plant
initialize[]