entity PGMerger is
	port (
		phi: in std_logic;
		ghi: in std_logic;
		plo: in std_logic;
		glo: in std_logic;
		pout: out std_logic;
		gout: out std_logic;
	);
end PropagateGenerateMerger;

entity HalfAdder is
	port (
		x1: in std_logic;
		x2: in std_logic;
		p: out std_logic;
		g: out std_logic;
	);
end HalfAdder;

entity FullAdder is
	port (
		x1: in std_logic;
		x2: in std_logic;
		x3: in std_logic;
		p: out std_logic;
		g: out std_logic;
	);
end FullAdder;


architecture PGMGate of PGMerger is
begin
	pout <= phi and plo
	gout <= (phi and glo) or ghi
end PGMGate;

architecture HAGate is
begin
	p <= x1 xor x2;
	g <= x1 and x2;
end HAGate;

architecture FAGate is
begin
	p <= (x1 xor x2) xor x3;
	g <= ((x1 and x2) or (x2 and x3)) or (x3 and x1);
end FAGate;
