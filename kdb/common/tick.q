\l schema.q

/ ======================= Tickerplant Setup ======================
logdir:"./logs";
system "mkdir -p ", logdir;

/ Tables allowed
tbls:`option_chain`nifty_opts`pnl`strategy_state`underlying`signals;
/ Initialize subscriber list so append won't fail
.tickSubscribers: ();

handleData:{[msg]
    table: msg`table;
    data:  msg`data;

    if[not table in tbls;
        show "ERROR: Unknown table: ", string table;
        :();
    ];

    switch[table;
        `option_chain;   option_chain insert data;
        `nifty_opts;     nifty_opts insert data;
        `pnl;            pnl insert data;
        `strategy_state; strategy_state insert data;
        `underlying;     underlying insert data;
        `signals;        signals insert data;
        _;               show "Unknown table in switch: ", string table
    ]};


/ ======================= subscribe / broadcast ==========================

subscribe:{[func]
    .tickSubscribers,:func};

broadcastData:{[table; data]
    do[foreach sub:.tickSubscribers; sub[table; data]]};

/ ======================= handleConnection ==========================
handleConnection:{[conn]
    show "handleConnection: got conn -> ", string conn;
    while[1;
        try:{
            / safe read using try/catch
            msg: ::;
            msg: try { conn 0: } catch { show "handleConnection: read error -> ", string x; :: };

            if[msg~::;
                / nothing read; break the loop
                show "handleConnection: no message, closing conn ", string conn;
                close conn;
                break;
            ];

            / got a message — process it
            handleData[msg];

            if[msg`table in `option_chain`nifty_opts;
                broadcastData[msg`table; msg`data];
            ];
        } catch {
            show "handleConnection: Exception -> ", string x;
            / Ensure conn closed on error
            catch { close conn };
            break;
        };
    ]};

/ ======================= Server Loop ==========================
server:{[port]
    h: hopen port;                         / listening handle
    -1 "Tickerplant listening on port ", string port;
    /show "Tickerplant listening on port ", string port, " (listen handle=", string h, ")";
    `$"Ticker Plant Started on port ", string port;

    while[1;
        / Accept connection (may return null if none)
        conn: first h;

        / Debug info to help trace 'type problems
        show "accept returned conn: ", string conn, "  type:", string type conn;

        / If conn is null or empty, wait and continue (avoid busy loop)
        if[conn~::;
            system "sleep 0.1";
            :();
        ];

        / If conn does not appear to be a scalar handle (defensive)
        if[count conn>1;
            -1 "accepted connection: ", string conn, " type=", string type conn;
            /show "accept returned a non-scalar conn (list), using first element";
            conn: first conn;
            show "using conn:", string conn;
        ];

        / final sanity check: ensure conn isn't null
        if[conn~::;
            show "conn still null after checks, continuing";
            sleep 100;
            continue;
        ];

        / Now attempt to read safely inside try/catch
        try:{
            msg: try { conn 0: } catch { show "server: read error -> ", string x; :: };

            if{not msg~::;
                handleData[msg];
            } else {
                show "server: no message (msg is null), closing conn ", string conn;
            };
        } catch {
            show "server: Exception when reading/processing -> ", string x;
        };

        / Always attempt to close the connection handle
        catch { close conn };
    ]};

/ ======================= Initialize ==========================
initialize:{
    show "Ticker Plant initialized with schema";
    server 5000};

initialize[];
