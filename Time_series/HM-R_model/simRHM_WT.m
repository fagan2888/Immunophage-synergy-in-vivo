%Function to simulate rhmODE for WT hosts
% inputs: (1)Ki- total immune capacity, (2)immune- initial immune response, 
%         (3)bacteria- initial bacteria conc., (4)phage- initial phage conc.
% outputs:(1)y- matrix of all of the population changes for bacteria,
%          phage and immune response.
%         (2)TB - vector of total bacteria populatino
%         (3)time - vector of time values over the simulation

function [ y, TB, time ] = simRHM_WT( Ki, immune, bacteria, phage )

    %---------parameters--------------
    % susceptible bacteria growth rate
    p.r = 0.75;
    % resistant bacteria growth rate
    p.rp = 0.675;
    % total bacteria carrying capacity
    p.Kc = 1e10;
    % nonlinear adsorption rate of phage:
    p.phi = 5.4e-8;
    % power law exponent in phage infection:
    p.g = 0.6;
    % immune response killing rate parameter:
    p.ep = 8.2e-8;
    % bacterial conc. at which immune response is half as effective:
    p.Kd = 4.1e7;
    % burst size of phage:
    p.beta = 100;
    % decay rate of phage:
    p.w = 0.07;
    % maximum growth rate of immune response:
    p.a = 0.97;
    % max capacity of immune response:
    p.Ki = Ki;
    % conc. of bacteria at which imm resp growth rate is half its maximum:
    p.Kn = 1e7;
    % probability of emergence of phage-resistant mutation per cell division
    p.m = 2.85e-8;

    %initial conditions
    Bo = bacteria;
    Ro = 0;
    Po = 0;
    Io = immune;
    tspan = 0:2;
    y0 = [Bo;Ro;Po;Io];

    % simulating diff eq until time to add phage (2hrs)
    options = odeset('Events',@myEventsFcn);
    [t1,y1] = ode45(@rhmODE,tspan,y0,options,p);

    %----------------------------------------
    % Add phage dose time delay (2hrs)

    B = y1(end,1);
    R = y1(end,2);
    P = phage;
    I = y1(end,4);
    tspan2 = 2:156;
    yi = [B;R;P;I];

    % simulating diff eq after phage addition
    [t2,y2] = ode45(@rhmODE,tspan2,yi,options,p);

    %----------------------------------------
    % continue simulation after susceptibles or resistants die

    check = 0;
    currentTime = t2(end);
    if currentTime < 155 % Bacterial pop died before end of simulation
        check = 1;
        B2 = y2(end,1);
        if B2 <= 1
            B2 = 0;
        end
        R2 = y2(end,2);
        if R2 <= 1
            R2 = 0;
        end
        P2 = y2(end,3);
        I2 = y2(end,4);
        tspan3 = currentTime:156;
        yii = [B2;R2;P2;I2];

        % simulating diff eq
        [t3,y3] = ode45(@rhmODE,tspan3,yii,options,p);
    end
    %----------------------------------------
    % continue simulation after susceptibles or resistants die

    % Check if run completed without bacteria dying
    if check == 1
        currentTime2 = t3(end);
    else
        currentTime2 = 156;
    end
    if currentTime2 < 155
        B3 = y3(end,1);
        if B3 <= 1
            B3 = 0;
        end
        R3 = y3(end,2);
        if R3 <= 1
            R3 = 0;
        end
        P3 = y3(end,3);
        I3 = y3(end,4);
        tspan4 = currentTime2:156;
        yiii = [B3;R3;P3;I3];

        % simulating diff eq
        [t4,y4] = ode45(@rhmODE,tspan4,yiii,options,p);

        time = [t1; t2; t3; t4];
        y = [y1; y2; y3; y4];
    elseif check == 1
        time = [t1; t2; t3];
        y = [y1; y2; y3];
    else
        y = [y1; y2;];
        time = [t1; t2];
    end
    S = y(:,1);
    R = y(:,2);
    TB = S + R;    
end

