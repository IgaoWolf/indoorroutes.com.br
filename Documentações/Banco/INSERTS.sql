INSERT INTO blocos (nome, descricao, latitude, longitude) 
VALUES ('Bloco 1', 'Bloco 1', -24.94633537, -53.50875386);

-- Inserir o Térreo no Bloco 1
INSERT INTO andares (bloco_id, numero, nome, altitude, altitude_min, altitude_max)
VALUES (1, 1, 'Térreo', 0.00, 0.00, 2.99);

SELECT * FROM andares WHERE bloco_id = 1 AND numero = 1;

-- Inserir Área de Circulação e Corredores no Térreo do Bloco 1
INSERT INTO waypoints (nome, descricao, tipo, bloco_id, andar_id, coordenadas) VALUES
-- Área de Circulação
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50890912, -24.94617105), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.5088367, -24.94613274), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50875154, -24.9461212), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50888967, -24.94619902), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50886955, -24.94622273), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50875416, -24.94657132), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.5087555, -24.94654009), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50876209, -24.94650461), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50876642, -24.94647659), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50877977, -24.94643436), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50878562, -24.94641059), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.5087947, -24.94638108), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50880189, -24.94635526), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50880866, -24.94633183), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50881628, -24.94630922), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50882548, -24.946288), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50883615, -24.94626633), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50885139, -24.94624444), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50881835, -24.94616601), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.5088064, -24.94619365), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50879446, -24.94621902), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50875087, -24.94615585), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50874874, -24.94618121), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50874758, -24.94620857), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.5086704, -24.94656032), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50859677, -24.94652202), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50861474, -24.9464939), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50863651, -24.94647167), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.508659, -24.94644587), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50867711, -24.94652369), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50869217, -24.94649372), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50870527, -24.94646715), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50874483, -24.94623246), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50873673, -24.94626412), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50878305, -24.94624644), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50877434, -24.94627441), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50876361, -24.94630005), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50872728, -24.94629231), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50875819, -24.94632216), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50871929, -24.94631674), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50875215, -24.94634592), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.5087118, -24.94633697), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50874215, -24.9463723), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50873343, -24.94640087), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50872069, -24.94642884), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50871332, -24.94644587), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50877501, -24.94645681), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50870326, -24.94636318), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50868961, -24.94638721), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50867979, -24.94641425), 4326)),
('Área de Circulação', 'Waypoint de circulação', 'circulacao', 1, 1, ST_SetSRID(ST_MakePoint(-53.50866919, -24.94643027), 4326)),

-- Corredores
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.509045, -24.946441), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50905036, -24.94641668), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50904055, -24.94638887), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50902823, -24.94636196), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50901562, -24.94633465), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50900141, -24.94631089), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50899001, -24.94629144), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50897983, -24.94627136), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50896929, -24.94625318), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50895484, -24.94622963), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50894033, -24.94620669), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50892454, -24.94619051), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50888766, -24.94615606), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50886072, -24.94614396), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50880719, -24.94612606), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50877977, -24.94612428), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50890308, -24.94614613), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50888766, -24.94611633), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50887693, -24.94609019), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50886687, -24.94606709), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50882932, -24.94607499), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50879677, -24.94608509), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50876849, -24.9460977), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50872673, -24.94611816), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50868662, -24.94613064), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50865028, -24.94614552), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50861536, -24.94615933), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50858, -24.94617663), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50854702, -24.94618929), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50851215, -24.94620449), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50848131, -24.94622152), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50844644, -24.94622334), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50842833, -24.94624948), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50845875, -24.94628358), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50846991, -24.94625313), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50846521, -24.94631089), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50847728, -24.94633339), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50848801, -24.94635831), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50849673, -24.94637838), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50850959, -24.94639933), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50852514, -24.94642701), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.5085383, -24.9464562), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50855354, -24.94647599), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50857232, -24.94649727), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50861724, -24.94653253), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50864541, -24.9465453), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50860402, -24.94655044), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50861877, -24.94657658), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50863352, -24.9466003), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50866839, -24.94660698), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.5087113, -24.94659604), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50871063, -24.94656868), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50879171, -24.94656419), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50881859, -24.94655652), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50885816, -24.94654254), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50889571, -24.94652977), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50893594, -24.94651214), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50896746, -24.94649937), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50899092, -24.94648903), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50901775, -24.94647383), 4326)),
('Corredor', 'Waypoint de corredor', 'corredor', 1, 1, ST_SetSRID(ST_MakePoint(-53.50903518, -24.94645863), 4326));


-- Inserir destinos associados aos waypoints relevantes
INSERT INTO destinos (nome, descricao, waypoint_id) VALUES
('Entrada do bloco pela Granvia', 'Entrada principal pela Granvia', (SELECT id FROM waypoints WHERE nome = 'Entrada do bloco pela Granvia' AND bloco_id = 1 AND andar_id = 1)),
('Entrada do bloco pela Reitoria', 'Entrada próxima à Reitoria', (SELECT id FROM waypoints WHERE nome = 'Entrada do bloco pela Reitoria 1' AND bloco_id = 1 AND andar_id = 1)),
('Entrada do bloco pelo Estacionamento', 'Entrada pelo estacionamento', (SELECT id FROM waypoints WHERE nome = 'Entrada do bloco pelo estacionamento' AND bloco_id = 1 AND andar_id = 1)),
('Entrada pelo bloco 2', 'Entrada de ligação com o bloco 2', (SELECT id FROM waypoints WHERE nome = 'Entrada pelo bloco 2 - Entrada 1' AND bloco_id = 1 AND andar_id = 1)),
('Escadaria Estacionamento', 'Escadaria próxima ao acesso do estacionamento', (SELECT id FROM waypoints WHERE nome = 'Escadaria - pelo acesso do estacionamento' AND bloco_id = 1 AND andar_id = 1)),
('Escadaria Granvia', 'Escadaria próxima ao acesso da granvia', (SELECT id FROM waypoints WHERE nome = 'Escadaria - pelo acesso da granvia' AND bloco_id = 1 AND andar_id = 1)),
('Elevador Granvia', 'Elevador próximo ao acesso da granvia', (SELECT id FROM waypoints WHERE nome = 'Elevador - pelo acesso da granvia' AND bloco_id = 1 AND andar_id = 1)),
('Lanchonete', 'Entrada da lanchonete', (SELECT id FROM waypoints WHERE nome = 'Entrada da Lanchonete' AND bloco_id = 1 AND andar_id = 1)),
('Fies', 'Entrada do Fies', (SELECT id FROM waypoints WHERE nome = 'Entrada do Fies' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Semiologia e Semiotecnica 2', 'Entrada da Sala de Semiologia e Semiotécnica 2', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Semiologia e Semiotecnica 2' AND bloco_id = 1 AND andar_id = 1)),
('Banco Itaú', 'Entrada do banco Itaú', (SELECT id FROM waypoints WHERE nome = 'Entrada do banco Itaú' AND bloco_id = 1 AND andar_id = 1)),
('Central de Reagentes', 'Entrada da Sala de Central de Reagentes', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Central de Reagentes' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Habilidades', 'Entrada da Sala de Habilidades', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Habilidades' AND bloco_id = 1 AND andar_id = 1)),
('Auditório', 'Entrada do Auditório', (SELECT id FROM waypoints WHERE nome = 'Entrada do Auditório' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Reprografia', 'Entrada da Sala de Reprografia', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Reprografia' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Anatomia 2', 'Entrada da Sala de Anatomia 2', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Anatomia 2' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Anatomia 1', 'Entrada da Sala de Anatomia 1', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Anatomia 1' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Tanques', 'Entrada da Sala de Tanques', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Tanques' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Anatomia 3 e Sala de Dissecação', 'Entrada da Sala de Anatomia 3 e Sala de Dissecação', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Anatomia 3 e Sala de Dissecação' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Coordenação dos Laboratórios', 'Entrada da Sala de Coordenação dos Laboratórios', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Coordenação dos Laboratórios' AND bloco_id = 1 AND andar_id = 1)),
('Museu de Ciências', 'Entrada para o Museu de Ciências', (SELECT id FROM waypoints WHERE nome = 'Entrada para o Museu de Ciências' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Professores Bloco 1', 'Entrada da Sala de Professores no Bloco 1', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Professores Bloco 1' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Interpretação Radiológica', 'Entrada da Sala de Interpretação Radiológica', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Interpretação Radiológica' AND bloco_id = 1 AND andar_id = 1)),
('NAAE e CEFAG', 'Entrada do NAAE e CEFAG', (SELECT id FROM waypoints WHERE nome = 'Entrada do NAAE e CEFAG' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Zoologia', 'Entrada da Sala de Zoologia', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Zoologia' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Distribuição de Equipamentos, Pesquisa/Apoio', 'Entrada da Sala de Distribuição de Equipamentos, Pesquisa e Apoio', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Distribuição de Equipamentos, Pesquisa/Apoio' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Microscopia', 'Entrada da Sala de Microscopia', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Microscopia' AND bloco_id = 1 AND andar_id = 1)),
('Sala CPD', 'Entrada da Sala CPD', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala CPD' AND bloco_id = 1 AND andar_id = 1)),
('Sala de Farmacologia', 'Entrada da Sala de Farmacologia', (SELECT id FROM waypoints WHERE nome = 'Entrada da Sala de Farmacologia' AND bloco_id = 1 AND andar_id = 1));

CREATE OR REPLACE FUNCTION preencher_conexoes_otimizado(raio_maximo NUMERIC)
RETURNS void AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
BEGIN
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints LOOP
        FOR waypoint_destino IN SELECT id, coordenadas FROM waypoints LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);

                -- Verificar se a distância está dentro do raio máximo permitido
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT preencher_conexoes_otimizado(20.0);
