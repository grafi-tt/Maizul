library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity finvTable is
  port (
    clk  : in  std_logic;
    addr : in  std_logic_vector(9 downto 0);
    output  : out std_logic_vector(35 downto 0) := (others => '0'));
end finvTable;

architecture box of finvTable is
  subtype table_rec_t is std_logic_vector(35 downto 0);
  type table_t is array (0 to 1023) of table_rec_t;
  constant table : table_t := (
x"FFFFF9FF8",
x"FF8019FE8",
x"FF0077FD8",
x"FE8117FC8",
x"FE01F7FB8",
x"FD8315FA8",
x"FD0471F98",
x"FC860DF89",
x"FC07E9F79",
x"FB8A01F6A",
x"FB0C59F5A",
x"FA8EEFF4B",
x"FA11C3F3B",
x"F994D5F2C",
x"F91823F1C",
x"F89BB1F0D",
x"F81F7BEFE",
x"F7A381EEF",
x"F727C5EDF",
x"F6AC47ED0",
x"F63103EC1",
x"F5B5FDEB2",
x"F53B33EA3",
x"F4C0A5E94",
x"F44653E85",
x"F3CC3BE76",
x"F35261E67",
x"F2D8C1E59",
x"F25F5DE4A",
x"F1E633E3B",
x"F16D45E2C",
x"F0F491E1E",
x"F07C17E0F",
x"F003D9E01",
x"EF8BD3DF2",
x"EF1409DE4",
x"EE9C79DD5",
x"EE2521DC7",
x"EDAE03DB9",
x"ED371FDAA",
x"ECC075D9C",
x"EC4A03D8E",
x"EBD3C9D80",
x"EB5DC9D71",
x"EAE801D63",
x"EA7271D55",
x"E9FD1BD47",
x"E987FBD39",
x"E91313D2B",
x"E89E65D1D",
x"E829EDD10",
x"E7B5ADD02",
x"E741A3CF4",
x"E6CDD1CE6",
x"E65A37CD8",
x"E5E6D3CCB",
x"E573A5CBD",
x"E500AFCB0",
x"E48DEFCA2",
x"E41B65C94",
x"E3A911C87",
x"E336F3C7A",
x"E2C50BC6C",
x"E25359C5F",
x"E1E1DBC51",
x"E17093C44",
x"E0FF81C37",
x"E08EA3C2A",
x"E01DFBC1C",
x"DFAD87C0F",
x"DF3D49C02",
x"DECD3DBF5",
x"DE5D67BE8",
x"DDEDC5BDB",
x"DD7E57BCE",
x"DD0F1DBC1",
x"DCA017BB4",
x"DC3145BA7",
x"DBC2A5B9A",
x"DB5439B8E",
x"DAE601B81",
x"DA77FBB74",
x"DA0A29B67",
x"D99C89B5B",
x"D92F1BB4E",
x"D8C1E1B42",
x"D854D9B35",
x"D7E803B28",
x"D77B5FB1C",
x"D70EEDB10",
x"D6A2ADB03",
x"D6369FAF7",
x"D5CAC1AEA",
x"D55F17ADE",
x"D4F39DAD2",
x"D48853AC5",
x"D41D3BAB9",
x"D3B255AAD",
x"D3479FAA1",
x"D2DD19A95",
x"D272C5A89",
x"D2089FA7D",
x"D19EABA71",
x"D134E7A65",
x"D0CB53A59",
x"D061EFA4D",
x"CFF8BBA41",
x"CF8FB5A35",
x"CF26DFA29",
x"CEBE39A1D",
x"CE55C3A11",
x"CDED7BA06",
x"CD85639FA",
x"CD1D799EE",
x"CCB5BD9E3",
x"CC4E319D7",
x"CBE6D39CB",
x"CB7FA59C0",
x"CB18A39B4",
x"CAB1CF9A9",
x"CA4B2B99D",
x"C9E4B3992",
x"C97E69986",
x"C9184F97B",
x"C8B261970",
x"C84C9F964",
x"C7E70B959",
x"C781A594E",
x"C71C6D943",
x"C6B75F937",
x"C6528192C",
x"C5EDCD921",
x"C58947916",
x"C524ED90B",
x"C4C0C1900",
x"C45CBF8F5",
x"C3F8EB8EA",
x"C395418DF",
x"C331C58D4",
x"C2CE738C9",
x"C26B4F8BE",
x"C208558B3",
x"C1A5858A8",
x"C142E389D",
x"C0E06B893",
x"C07E1F888",
x"C01BFD87D",
x"BFBA05873",
x"BF5839868",
x"BEF69985D",
x"BE9521853",
x"BE33D5848",
x"BDD2B383D",
x"BD71BB833",
x"BD10EF828",
x"BCB04B81E",
x"BC4FD1813",
x"BBEF81809",
x"BB8F5B7FF",
x"BB2F5F7F4",
x"BACF8D7EA",
x"BA6FE37E0",
x"BA10637D5",
x"B9B10B7CB",
x"B951DD7C1",
x"B8F2D97B7",
x"B893FD7AC",
x"B835497A2",
x"B7D6BF798",
x"B7785D78E",
x"B71A23784",
x"B6BC1377A",
x"B65E29770",
x"B60069766",
x"B5A2CF75C",
x"B5455F752",
x"B4E817748",
x"B48AF573E",
x"B42DFB734",
x"B3D12B72A",
x"B3747F720",
x"B317FD716",
x"B2BBA170D",
x"B25F6D703",
x"B2035F6F9",
x"B1A7796EF",
x"B14BB96E6",
x"B0F0216DC",
x"B094AF6D2",
x"B039636C9",
x"AFDE3D6BF",
x"AF833F6B6",
x"AF28676AC",
x"AECDB56A2",
x"AE7329699",
x"AE18C368F",
x"ADBE83686",
x"AD646967D",
x"AD0A75673",
x"ACB0A766A",
x"AC56FD660",
x"ABFD79657",
x"ABA41B64E",
x"AB4AE3644",
x"AAF1CF63B",
x"AA98DF632",
x"AA4017629",
x"A9E77161F",
x"A98EF1616",
x"A9369760D",
x"A8DE5F604",
x"A8864D5FB",
x"A82E615F2",
x"A7D6975E9",
x"A77EF35E0",
x"A727735D7",
x"A6D0155CE",
x"A678DD5C5",
x"A621C95BC",
x"A5CAD95B3",
x"A5740D5AA",
x"A51D635A1",
x"A4C6DD598",
x"A4707B58F",
x"A41A3D586",
x"A3C42357D",
x"A36E2B575",
x"A3185556C",
x"A2C2A5563",
x"A26D1555A",
x"A217A9552",
x"A1C261549",
x"A16D3B540",
x"A11837538",
x"A0C35752F",
x"A06E99526",
x"A019FD51E",
x"9FC583515",
x"9F712D50D",
x"9F1CF7504",
x"9EC8E54FC",
x"9E74F54F3",
x"9E21254EB",
x"9DCD794E2",
x"9D79ED4DA",
x"9D26834D1",
x"9CD33B4C9",
x"9C80154C1",
x"9C2D114B8",
x"9BDA2D4B0",
x"9B876B4A8",
x"9B34CB49F",
x"9AE24B497",
x"9A8FEB48F",
x"9A3DAF487",
x"99EB9147E",
x"999995476",
x"9947BB46E",
x"98F5FF466",
x"98A46745E",
x"9852ED456",
x"98019344E",
x"97B05B446",
x"975F4343D",
x"970E4B435",
x"96BD7342D",
x"966CBD425",
x"961C2541D",
x"95CBAD415",
x"957B5540E",
x"952B1D406",
x"94DB053FE",
x"948B0B3F6",
x"943B333EE",
x"93EB793E6",
x"939BDF3DE",
x"934C653D6",
x"92FD093CF",
x"92ADCD3C7",
x"925EAF3BF",
x"920FB13B7",
x"91C0D13B0",
x"9172113A8",
x"91236F3A0",
x"90D4ED398",
x"908689391",
x"903845389",
x"8FEA1D382",
x"8F9C1537A",
x"8F4E2B372",
x"8F005F36B",
x"8EB2B3363",
x"8E652335C",
x"8E17B3354",
x"8DCA6134D",
x"8D7D2B345",
x"8D301533E",
x"8CE31D336",
x"8C964132F",
x"8C4983327",
x"8BFCE5320",
x"8BB063319",
x"8B63FD311",
x"8B17B730A",
x"8ACB8D303",
x"8A7F812FB",
x"8A33932F4",
x"89E7C12ED",
x"899C0B2E5",
x"8950752DE",
x"8904F92D7",
x"88B99D2D0",
x"886E5B2C8",
x"8823372C1",
x"87D8312BA",
x"878D472B3",
x"8742792AC",
x"86F7C72A5",
x"86AD3329E",
x"8662B9296",
x"86185D28F",
x"85CE1F288",
x"8583FB281",
x"8539F327A",
x"84F009273",
x"84A63926C",
x"845C87265",
x"8412EF25E",
x"83C975257",
x"838015250",
x"8336D124A",
x"82EDA9243",
x"82A49D23C",
x"825BAB235",
x"8212D722E",
x"81CA1D227",
x"81817F220",
x"8138FB219",
x"80F093213",
x"80A84720C",
x"806015205",
x"8017FF1FE",
x"7FD0031F8",
x"7F88231F1",
x"7F405D1EA",
x"7EF8B11E4",
x"7EB1211DD",
x"7E69AD1D6",
x"7E22511D0",
x"7DDB111C9",
x"7D93ED1C2",
x"7D4CE11BC",
x"7D05F11B5",
x"7CBF1B1AE",
x"7C785F1A8",
x"7C31BD1A1",
x"7BEB3519B",
x"7BA4C9194",
x"7B5E7518E",
x"7B183D187",
x"7AD21D181",
x"7A8C1917A",
x"7A462D174",
x"7A005B16D",
x"79BAA3167",
x"797505161",
x"792F8115A",
x"78EA17154",
x"78A4C514D",
x"785F8D147",
x"781A6F141",
x"77D56913A",
x"77907D134",
x"774BAB12E",
x"7706F3128",
x"76C253121",
x"767DCB11B",
x"76395D115",
x"75F50910F",
x"75B0CD108",
x"756CA9102",
x"75289F0FC",
x"74E4AD0F6",
x"74A0D50F0",
x"745D150E9",
x"74196D0E3",
x"73D5DD0DD",
x"7392670D7",
x"734F090D1",
x"730BC30CB",
x"72C8970C5",
x"7285810BF",
x"7242850B9",
x"71FFA10B3",
x"71BCD50AD",
x"717A1F0A7",
x"7137830A1",
x"70F4FF09B",
x"70B293095",
x"70703F08F",
x"702E03089",
x"6FEBDF083",
x"6FA9D107D",
x"6F67DD077",
x"6F25FF071",
x"6EE43906B",
x"6EA28B065",
x"6E60F305F",
x"6E1F7305A",
x"6DDE0B054",
x"6D9CBB04E",
x"6D5B81048",
x"6D1A5F042",
x"6CD95503C",
x"6C9861037",
x"6C5785031",
x"6C16BF02B",
x"6BD60F025",
x"6B9579020",
x"6B54F701A",
x"6B148D014",
x"6AD43B00F",
x"6A93FF009",
x"6A53D9003",
x"6A13CAFFE",
x"69D3D2FF8",
x"6993F0FF2",
x"695424FED",
x"691470FE7",
x"68D4D2FE1",
x"68954AFDC",
x"6855D8FD6",
x"68167EFD1",
x"67D738FCB",
x"67980AFC6",
x"6758F2FC0",
x"6719F0FBB",
x"66DB04FB5",
x"669C2EFB0",
x"665D6EFAA",
x"661EC2FA5",
x"65E02EF9F",
x"65A1B0F9A",
x"656348F94",
x"6524F4F8F",
x"64E6B8F89",
x"64A890F84",
x"646A7EF7F",
x"642C82F79",
x"63EE9CF74",
x"63B0CAF6E",
x"63730EF69",
x"633568F64",
x"62F7D6F5E",
x"62BA5CF59",
x"627CF4F54",
x"623FA4F4E",
x"620268F49",
x"61C542F44",
x"618830F3F",
x"614B32F39",
x"610E4CF34",
x"60D178F2F",
x"6094BCF2A",
x"605812F24",
x"601B7EF1F",
x"5FDF00F1A",
x"5FA296F15",
x"5F6640F10",
x"5F29FEF0B",
x"5EEDD2F05",
x"5EB1BCF00",
x"5E75B8EFB",
x"5E39CAEF6",
x"5DFDF0EF1",
x"5DC22AEEC",
x"5D8678EE7",
x"5D4ADCEE2",
x"5D0F54EDD",
x"5CD3E0ED7",
x"5C9880ED2",
x"5C5D34ECD",
x"5C21FCEC8",
x"5BE6D8EC3",
x"5BABC8EBE",
x"5B70CEEB9",
x"5B35E6EB4",
x"5AFB12EAF",
x"5AC054EAA",
x"5A85A8EA5",
x"5A4B10EA0",
x"5A108CE9C",
x"59D61CE97",
x"599BC0E92",
x"596176E8D",
x"592742E88",
x"58ED20E83",
x"58B312E7E",
x"587918E79",
x"583F30E74",
x"58055CE70",
x"57CB9CE6B",
x"5791F0E66",
x"575856E61",
x"571ED0E5C",
x"56E55EE57",
x"56ABFEE53",
x"5672B2E4E",
x"563978E49",
x"560052E44",
x"55C740E40",
x"558E40E3B",
x"555552E36",
x"551C78E31",
x"54E3B0E2D",
x"54AAFCE28",
x"54725CE23",
x"5439CCE1E",
x"540150E1A",
x"53C8E8E15",
x"539092E10",
x"53584EE0C",
x"53201CE07",
x"52E7FEE02",
x"52AFF2DFE",
x"5277F8DF9",
x"524012DF5",
x"52083EDF0",
x"51D07CDEB",
x"5198CCDE7",
x"51612EDE2",
x"5129A4DDE",
x"50F22ADD9",
x"50BAC4DD5",
x"508370DD0",
x"504C2EDCB",
x"5014FEDC7",
x"4FDDE0DC2",
x"4FA6D4DBE",
x"4F6FDADB9",
x"4F38F2DB5",
x"4F021EDB0",
x"4ECB5ADAC",
x"4E94A8DA8",
x"4E5E08DA3",
x"4E2778D9F",
x"4DF0FCD9A",
x"4DBA92D96",
x"4D8438D91",
x"4D4DF2D8D",
x"4D17BCD89",
x"4CE198D84",
x"4CAB86D80",
x"4C7584D7B",
x"4C3F94D77",
x"4C09B8D73",
x"4BD3EAD6E",
x"4B9E30D6A",
x"4B6886D66",
x"4B32EED61",
x"4AFD66D5D",
x"4AC7F2D59",
x"4A928CD54",
x"4A5D3AD50",
x"4A27F8D4C",
x"49F2C6D47",
x"49BDA8D43",
x"498898D3F",
x"49539CD3B",
x"491EAED36",
x"48E9D4D32",
x"48B508D2E",
x"488050D2A",
x"484BA6D25",
x"48170ED21",
x"47E288D1D",
x"47AE12D19",
x"4779ACD15",
x"474558D10",
x"471114D0C",
x"46DCE0D08",
x"46A8BED04",
x"4674ACD00",
x"4640AACFC",
x"460CBACF8",
x"45D8DACF3",
x"45A50ACEF",
x"45714ACEB",
x"453D9CCE7",
x"4509FCCE3",
x"44D66ECDF",
x"44A2F0CDB",
x"446F84CD7",
x"443C26CD3",
x"4408DACCF",
x"43D59CCCB",
x"43A270CC7",
x"436F54CC3",
x"433C48CBF",
x"43094CCBB",
x"42D660CB6",
x"42A384CB2",
x"4270B8CAE",
x"423DFCCAB",
x"420B50CA7",
x"41D8B4CA3",
x"41A628C9F",
x"4173AAC9B",
x"41413EC97",
x"410EE2C93",
x"40DC94C8F",
x"40AA58C8B",
x"40782AC87",
x"40460CC83",
x"4013FEC7F",
x"3FE200C7B",
x"3FB012C77",
x"3F7E32C73",
x"3F4C62C70",
x"3F1AA2C6C",
x"3EE8F2C68",
x"3EB750C64",
x"3E85BEC60",
x"3E543CC5C",
x"3E22C8C58",
x"3DF166C55",
x"3DC010C51",
x"3D8ECCC4D",
x"3D5D96C49",
x"3D2C70C45",
x"3CFB58C42",
x"3CCA50C3E",
x"3C9958C3A",
x"3C686EC36",
x"3C3792C32",
x"3C06C8C2F",
x"3BD60AC2B",
x"3BA55EC27",
x"3B74BEC23",
x"3B4430C20",
x"3B13AEC1C",
x"3AE33CC18",
x"3AB2DAC14",
x"3A8286C11",
x"3A5240C0D",
x"3A220AC09",
x"39F1E2C06",
x"39C1CAC02",
x"3991C0BFE",
x"3961C4BFB",
x"3931D8BF7",
x"3901FABF3",
x"38D22ABF0",
x"38A26ABEC",
x"3872B8BE8",
x"384314BE5",
x"38137EBE1",
x"37E3F8BDE",
x"37B480BDA",
x"378516BD6",
x"3755BABD3",
x"37266EBCF",
x"36F72EBCC",
x"36C7FEBC8",
x"3698DCBC4",
x"3669C8BC1",
x"363AC4BBD",
x"360BCCBBA",
x"35DCE4BB6",
x"35AE08BB3",
x"357F3CBAF",
x"35507EBAC",
x"3521CCBA8",
x"34F32ABA5",
x"34C496BA1",
x"349610B9E",
x"346798B9A",
x"34392EB97",
x"340AD2B93",
x"33DC84B90",
x"33AE42B8C",
x"338010B89",
x"3351ECB85",
x"3323D6B82",
x"32F5CCB7E",
x"32C7D0B7B",
x"3299E4B77",
x"326C04B74",
x"323E32B71",
x"32106EB6D",
x"31E2B8B6A",
x"31B50EB66",
x"318772B63",
x"3159E6B60",
x"312C66B5C",
x"30FEF2B59",
x"30D18EB55",
x"30A436B52",
x"3076ECB4F",
x"3049B0B4B",
x"301C80B48",
x"2FEF5EB45",
x"2FC24AB41",
x"2F9542B3E",
x"2F684AB3B",
x"2F3B5CB37",
x"2F0E7EB34",
x"2EE1ACB31",
x"2EB4E8B2D",
x"2E8830B2A",
x"2E5B86B27",
x"2E2EEAB23",
x"2E025AB20",
x"2DD5D6B1D",
x"2DA962B1A",
x"2D7CF8B16",
x"2D509EB13",
x"2D2450B10",
x"2CF80EB0D",
x"2CCBDAB09",
x"2C9FB2B06",
x"2C7398B03",
x"2C478AB00",
x"2C1B8AAFC",
x"2BEF96AF9",
x"2BC3B0AF6",
x"2B97D6AF3",
x"2B6C08AF0",
x"2B4048AEC",
x"2B1494AE9",
x"2AE8EEAE6",
x"2ABD54AE3",
x"2A91C6AE0",
x"2A6646ADC",
x"2A3AD2AD9",
x"2A0F6AAD6",
x"29E410AD3",
x"29B8C2AD0",
x"298D80ACD",
x"29624CACA",
x"293724AC6",
x"290C08AC3",
x"28E0F8AC0",
x"28B5F6ABD",
x"288AFEABA",
x"286014AB7",
x"283538AB4",
x"280A66AB1",
x"27DFA0AAE",
x"27B4E8AAB",
x"278A3CAA7",
x"275F9CAA4",
x"273508AA1",
x"270A82A9E",
x"26E006A9B",
x"26B598A98",
x"268B36A95",
x"2660DEA92",
x"263694A8F",
x"260C56A8C",
x"25E224A89",
x"25B7FEA86",
x"258DE4A83",
x"2563D8A80",
x"2539D6A7D",
x"250FE0A7A",
x"24E5F6A77",
x"24BC18A74",
x"249246A71",
x"246880A6E",
x"243EC8A6B",
x"24151AA68",
x"23EB76A65",
x"23C1E0A62",
x"239856A5F",
x"236ED8A5C",
x"234566A59",
x"231BFEA56",
x"22F2A2A53",
x"22C954A50",
x"22A010A4E",
x"2276D8A4B",
x"224DACA48",
x"22248AA45",
x"21FB76A42",
x"21D26CA3F",
x"21A96EA3C",
x"21807CA39",
x"215796A36",
x"212EBAA33",
x"2105EAA31",
x"20DD26A2E",
x"20B46EA2B",
x"208BC2A28",
x"206320A25",
x"203A8AA22",
x"2011FEA1F",
x"1FE980A1C",
x"1FC10CA1A",
x"1F98A2A17",
x"1F7046A14",
x"1F47F4A11",
x"1F1FACA0E",
x"1EF772A0C",
x"1ECF42A09",
x"1EA71CA06",
x"1E7F02A03",
x"1E56F4A00",
x"1E2EF29FE",
x"1E06FA9FB",
x"1DDF0C9F8",
x"1DB72A9F5",
x"1D8F549F2",
x"1D67889F0",
x"1D3FC89ED",
x"1D18129EA",
x"1CF0689E7",
x"1CC8CA9E5",
x"1CA1349E2",
x"1C79AC9DF",
x"1C522E9DC",
x"1C2ABA9DA",
x"1C03529D7",
x"1BDBF49D4",
x"1BB4A29D1",
x"1B8D5A9CF",
x"1B661E9CC",
x"1B3EEC9C9",
x"1B17C49C7",
x"1AF0A89C4",
x"1AC9969C1",
x"1AA2909BE",
x"1A7B949BC",
x"1A54A29B9",
x"1A2DBC9B6",
x"1A06E09B4",
x"19E0109B1",
x"19B9489AE",
x"19928E9AC",
x"196BDC9A9",
x"1945369A6",
x"191E9A9A4",
x"18F8089A1",
x"18D18299F",
x"18AB0699C",
x"188494999",
x"185E2E997",
x"1837D0994",
x"18117E991",
x"17EB3898F",
x"17C4FA98C",
x"179EC898A",
x"1778A0987",
x"175282984",
x"172C6E982",
x"17066497F",
x"16E06697D",
x"16BA7297A",
x"169488977",
x"166EA8975",
x"1648D2972",
x"162308970",
x"15FD4696D",
x"15D79096B",
x"15B1E4968",
x"158C42966",
x"1566AA963",
x"15411C960",
x"151B9895E",
x"14F61E95B",
x"14D0B0959",
x"14AB4A956",
x"1485EE954",
x"14609E951",
x"143B5694F",
x"14161A94C",
x"13F0E694A",
x"13CBBE947",
x"13A69E945",
x"13818A942",
x"135C7E940",
x"13377E93D",
x"13128693B",
x"12ED9A938",
x"12C8B6936",
x"12A3DE933",
x"127F0E931",
x"125A4892E",
x"12358C92C",
x"1210DA92A",
x"11EC32927",
x"11C794925",
x"11A300922",
x"117E74920",
x"1159F491D",
x"11357C91B",
x"11110E918",
x"10ECAC916",
x"10C850914",
x"10A400911",
x"107FBA90F",
x"105B7C90C",
x"10374A90A",
x"101320908",
x"0FEEFE905",
x"0FCAE8903",
x"0FA6DC900",
x"0F82D88FE",
x"0F5EDE8FC",
x"0F3AEC8F9",
x"0F17068F7",
x"0EF3288F4",
x"0ECF548F2",
x"0EAB8A8F0",
x"0E87C88ED",
x"0E64128EB",
x"0E40648E9",
x"0E1CBE8E6",
x"0DF9248E4",
x"0DD5928E2",
x"0DB2088DF",
x"0D8E8A8DD",
x"0D6B148DB",
x"0D47A68D8",
x"0D24448D6",
x"0D00EA8D4",
x"0CDD988D1",
x"0CBA528CF",
x"0C97128CD",
x"0C73DE8CA",
x"0C50B28C8",
x"0C2D908C6",
x"0C0A768C4",
x"0BE7668C1",
x"0BC4608BF",
x"0BA1628BD",
x"0B7E6C8BA",
x"0B5B828B8",
x"0B389E8B6",
x"0B15C68B4",
x"0AF2F68B1",
x"0AD02E8AF",
x"0AAD708AD",
x"0A8ABA8AB",
x"0A680E8A8",
x"0A456C8A6",
x"0A22D28A4",
x"0A00408A2",
x"09DDB889F",
x"09BB3A89D",
x"0998C489B",
x"097656899",
x"0953F2896",
x"093196894",
x"090F44892",
x"08ECFA890",
x"08CABA88D",
x"08A88288B",
x"088652889",
x"08642C887",
x"08420E885",
x"081FFA882",
x"07FDEE880",
x"07DBEA87E",
x"07B9F087C",
x"0797FE87A",
x"077616878",
x"075436875",
x"07325E873",
x"071090871",
x"06EECA86F",
x"06CD0C86D",
x"06AB5886B",
x"0689AC868",
x"066808866",
x"06466E864",
x"0624DC862",
x"060352860",
x"05E1D085E",
x"05C05885B",
x"059EE8859",
x"057D80857",
x"055C22855",
x"053ACC853",
x"05197E851",
x"04F83884F",
x"04D6FC84D",
x"04B5C684A",
x"04949A848",
x"047378846",
x"04525C844",
x"04314A842",
x"04103E840",
x"03EF3E83E",
x"03CE4483C",
x"03AD5283A",
x"038C6A838",
x"036B88836",
x"034AB0833",
x"0329E0831",
x"03091A82F",
x"02E85A82D",
x"02C7A282B",
x"02A6F4829",
x"02864E827",
x"0265B0825",
x"02451A823",
x"02248C821",
x"02040681F",
x"01E38881D",
x"01C31481B",
x"01A2A6819",
x"018242817",
x"0161E4815",
x"014190813",
x"012144811",
x"0100FE80F",
x"00E0C280D",
x"00C08E80B",
x"00A062809",
x"00803E807",
x"006022805",
x"00400E803",
x"002002801");
  
begin  -- box
  process(clk)
    begin
      if rising_edge(clk) then
        output <= table(conv_integer(addr));
      end if;  
  end process;
end box;
