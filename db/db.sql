SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS Comune;
DROP TABLE IF EXISTS Parcheggio;
DROP TABLE IF EXISTS Destinazione;
DROP TABLE IF EXISTS Utente;
DROP TABLE IF EXISTS Veicolo;
DROP TABLE IF EXISTS Distributore;
DROP TABLE IF EXISTS Settimana;
DROP TABLE IF EXISTS Recensioni;
DROP TABLE IF EXISTS Proprieta;
DROP TABLE IF EXISTS Apertura;
DROP TABLE IF EXISTS Orario;
DROP TABLE IF EXISTS Disponibilita;
DROP TABLE IF EXISTS Rilevamento;
DROP TABLE IF EXISTS Applicato;
DROP TABLE IF EXISTS Riferita;

DROP TRIGGER IF EXISTS ControllaCoincidenze;
DROP TRIGGER IF EXISTS ControllaMail;
DROP TRIGGER IF EXISTS SoloRecensioniCustoditi;

DROP FUNCTION IF EXISTS Distanza;
DROP FUNCTION IF EXISTS TrovaClasse;

CREATE TABLE Comune (
Nome VARCHAR(20) PRIMARY KEY,
LimiteBenz VARCHAR(6) DEFAULT NULL,
LimiteDiesel VARCHAR(6) DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE Parcheggio (
Id CHAR (8) PRIMARY KEY,
Nome VARCHAR (35) NOT NULL,
Indirizzo VARCHAR (35),
Latitudine DOUBLE (10,7) NOT NULL,
Longitudine DOUBLE (10,7) NOT NULL,
Custodito BOOLEAN DEFAULT FALSE,
Coperto BOOLEAN DEFAULT FALSE,
Riservato VARCHAR (25) DEFAULT NULL,
Comune VARCHAR(20),

UNIQUE (Nome, Latitudine, Longitudine),
FOREIGN KEY (Comune) REFERENCES Comune(Nome)
)ENGINE=InnoDB;

CREATE TABLE Destinazione (
Id CHAR (8) PRIMARY KEY,
Nome VARCHAR (35) NOT NULL,
Indirizzo VARCHAR (35),
Latitudine DOUBLE (10,7) NOT NULL,
Longitudine DOUBLE (10,7) NOT NULL,
Comune VARCHAR(20),

UNIQUE ( Nome, Latitudine, Longitudine),
FOREIGN KEY (Comune) REFERENCES Comune(Nome)
)ENGINE=InnoDB;

CREATE TABLE Utente (
Mail VARCHAR (100) UNIQUE NOT NULL,
Username VARCHAR (20) PRIMARY KEY,
Password CHAR(40) NOT NULL,
Conferma CHAR (6) UNIQUE DEFAULT NULL,
DataIscrizione DATETIME DEFAULT CURRENT_TIMESTAMP
)ENGINE=InnoDB;

CREATE TABLE Veicolo (
Classe VARCHAR (15) PRIMARY KEY,
PesoMassimo FLOAT(4,2) UNSIGNED DEFAULT NULL,
LunghezzaMassima FLOAT(4,2) UNSIGNED DEFAULT NULL,
LarghezzaMassima FLOAT(4,2) UNSIGNED DEFAULT NULL,
AltezzaMassima FLOAT(4,2) UNSIGNED DEFAULT NULL,
PotenzaMassima SMALLINT UNSIGNED DEFAULT NULL,
CilindrataMassima SMALLINT UNSIGNED DEFAULT NULL

)ENGINE=InnoDB;

CREATE TABLE Distributore (
Id CHAR(6) PRIMARY KEY,
Indirizzo VARCHAR(35),
Nome VARCHAR (25) NOT NULL,
Latitudine DOUBLE (10,7) NOT NULL,
Longitudine DOUBLE (10,7) NOT NULL,
Comune VARCHAR(20),

UNIQUE ( Nome, Latitudine, Longitudine),
FOREIGN KEY (Comune) REFERENCES Comune(Nome)
)ENGINE=InnoDB;

CREATE TABLE Giorno (
Nome VARCHAR (10) PRIMARY KEY,
Festivo BOOLEAN DEFAULT FALSE
)ENGINE=InnoDB;

CREATE TABLE Recensione (
IdP CHAR(8),
NickU VARCHAR (20),
DataR DATETIME DEFAULT CURRENT_TIMESTAMP,
Testo VARCHAR (140) DEFAULT NULL,
Voto TINYINT,

PRIMARY KEY (IdP, NickU),
FOREIGN KEY (IdP) REFERENCES Parcheggio (Id)
ON UPDATE CASCADE
ON DELETE CASCADE,
FOREIGN KEY (NickU) REFERENCES Utente (Username)
ON UPDATE CASCADE
ON DELETE NO ACTION
)ENGINE=InnoDB;

CREATE TABLE Proprieta (
IdL CHAR (8),
IdP CHAR (8),

PRIMARY KEY (IdL, IdP),
FOREIGN KEY (IdP) REFERENCES Parcheggio (Id)
ON UPDATE CASCADE
ON DELETE CASCADE,
FOREIGN KEY (IdL) REFERENCES Destinazione (Id)
ON UPDATE CASCADE
ON DELETE CASCADE
)ENGINE=InnoDB;

CREATE TABLE Apertura (
Id CHAR (10) PRIMARY KEY,
IdL CHAR (8),
HAperto TIME,
HChiuso TIME,

UNIQUE (IdL, HAperto, HChiuso),
FOREIGN KEY (IdL) REFERENCES Destinazione (Id)
ON UPDATE CASCADE
ON DELETE CASCADE
)ENGINE=InnoDB;

CREATE TABLE Orario (
Id CHAR (10) PRIMARY KEY,
IdP CHAR (8),
HInizio TIME,
HFine TIME,
PrezzoH FLOAT(4,2) DEFAULT 0,
Sosta TIME DEFAULT NULL,

UNIQUE (IdP, HInizio, HFine, PrezzoH),
FOREIGN KEY (IdP) REFERENCES Parcheggio (Id)
ON UPDATE CASCADE
ON DELETE CASCADE
)ENGINE=InnoDB;

CREATE TABLE Disponibilita(
IdO CHAR (10),
ClasseV VARCHAR (15),
NPosti SMALLINT UNSIGNED,
ScontoDisabili FLOAT(4,2) DEFAULT 0,

PRIMARY KEY (IdO, ClasseV),
FOREIGN KEY (IdO) REFERENCES Orario (Id)
ON UPDATE CASCADE
ON DELETE CASCADE,
FOREIGN KEY (ClasseV) REFERENCES Veicolo (Classe)
ON UPDATE CASCADE
ON DELETE CASCADE
)ENGINE=InnoDB;

CREATE TABLE Rilevamento(
IdD CHAR(6),
TipoC VARCHAR(12) DEFAULT "Senza Piombo",
Data DATETIME DEFAULT CURRENT_TIMESTAMP,
NickIns VARCHAR(20),
Prezzo FLOAT(4,3) NOT NULL,

PRIMARY KEY (IdD, TipoC, Data, NickIns),
FOREIGN KEY (NickIns) REFERENCES Utente(Username)
ON UPDATE CASCADE
ON DELETE NO ACTION,
FOREIGN KEY (IdD) REFERENCES Distributore(Id)
ON UPDATE CASCADE
ON DELETE CASCADE
)ENGINE=InnoDB;

CREATE TABLE Applicato (
IdO CHAR (10),
GiornoS VARCHAR (10),

PRIMARY KEY (IdO, GiornoS),
FOREIGN KEY (IdO) REFERENCES Orario(Id)
ON UPDATE CASCADE
ON DELETE CASCADE,
FOREIGN KEY (GiornoS) REFERENCES Giorno(Nome)
ON UPDATE CASCADE
ON DELETE CASCADE
)ENGINE=InnoDB;

CREATE TABLE Riferita (
IdA CHAR (10),
GiornoS VARCHAR (10),

PRIMARY KEY (IdA, GiornoS),
FOREIGN KEY (IdA) REFERENCES Apertura(Id)
ON UPDATE CASCADE
ON DELETE CASCADE,
FOREIGN KEY (GiornoS) REFERENCES Giorno(Nome)
ON UPDATE CASCADE
ON DELETE CASCADE
)ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS=1;

# Questo trigger verifica che il testo inserito nel campo Mail abbia
# effettivamente la struttura di un indirizzo email, ovvero contenga al suo interno una
# chiocciola “@” e un punto “.”, se così non fosse, restituisce un errore nel quale
# indica il problema.

DELIMITER |
CREATE TRIGGER ControllaMail BEFORE INSERT ON Utente
FOR EACH ROW
BEGIN
IF New.Mail NOT LIKE '%@%.%' THEN
 SIGNAL SQLSTATE '45000'
 SET MESSAGE_TEXT = "Il testo inserito nel campo mail non è valido";
END IF;
END |
DELIMITER ;

# Questo trigger verifica che le recensioni inserite nel
# database siano associate solo a parcheggi custoditi, come richiesto dai requisiti, nel
# caso non fosse così, restituisce un errore nel quale indica il problema.

DELIMITER |
CREATE TRIGGER SoloRecensioniCustoditi BEFORE INSERT ON Recensione
FOR EACH ROW
BEGIN
DECLARE C BOOLEAN;
SELECT Custodito INTO C
FROM Parcheggio
WHERE Id=New.IdP;
IF C = FALSE THEN
 SIGNAL SQLSTATE '45000'
 SET MESSAGE_TEXT = "Stai recensendo un parcheggio non custodito";
END IF;
END |
DELIMITER ;

# Questo trigger evita che un tipo di veicoli possa essere
# inserito con due prezzi differenti contemporaneamente agli stessi orari

DELIMITER |
CREATE TRIGGER ControllaCoincidenze BEFORE INSERT ON Disponibilita
FOR EACH ROW
BEGIN
DECLARE Found INT;
SELECT COUNT(*) INTO Found
FROM
(SELECT IdP,HInizio,HFine,GiornoS
FROM Orario INNER JOIN Applicato ON Orario.Id=IdO INNER JOIN Disponibilita ON Disponibilita.IdO=Orario.Id 
WHERE ClasseV=New.ClasseV) V
JOIN
(SELECT IdP,HInizio,HFine,GiornoS
FROM Orario INNER JOIN Applicato ON Orario.Id=IdO INNER JOIN Disponibilita ON Disponibilita.IdO=Orario.Id 
WHERE Orario.Id LIKE New.IdO) O
ON V.IdP=O.IdP
WHERE V.GiornoS=O.GiornoS AND (O.HInizio<=V.HFine AND O.HFine>=V.HInizio);
IF Found > 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = "Stai inserendo un prezzo per un veicolo già presente in questi orari";
END IF;
END |
DELIMITER ;

# Questa funzione sfrutta la presenza delle coordinate del database per
# calcolare la distanza in linea d’aria tra due luoghi.

DELIMITER |
CREATE FUNCTION Distanza (Lat1 DOUBLE (10,7), Lon1 DOUBLE (10,7), Lat2 DOUBLE (10,7), Lon2 DOUBLE (10,7))
RETURNS FLOAT(5,2)
BEGIN
DECLARE  D DOUBLE (10,7);
SET D =(6371*3.1415926*sqrt((Lat2-Lat1)*(Lat2-Lat1) + cos(Lat2/57.29578)*cos(Lat1/57.29578)*(Lon2-Lon1)*(Lon2-Lon1))/180);
RETURN D;
END|
DELIMITER ;

# Questa funzione, nel caso in cui non si conosca la classe di un
# veicolo, permette date le misure di trovare quella minore che accetta le sue
# caratteristiche.

DELIMITER |
CREATE FUNCTION TrovaClasse (Peso FLOAT(4,2) UNSIGNED, Lunghezza FLOAT(4,2) UNSIGNED, Larghezza FLOAT(4,2) UNSIGNED, Altezza FLOAT(4,2) UNSIGNED, Potenza SMALLINT UNSIGNED, Cilindrata SMALLINT UNSIGNED)
RETURNS VARCHAR(15)
BEGIN
DECLARE ClasseTrovata VARCHAR(15);
SELECT Classe INTO ClasseTrovata
FROM Veicolo
WHERE (Peso <= PesoMassimo OR PesoMassimo IS NULL) AND
(Lunghezza <= LunghezzaMassima OR LunghezzaMassima IS NULL) AND
(Larghezza <= LarghezzaMassima OR LarghezzaMassima IS NULL) AND
(Altezza <= AltezzaMassima OR AltezzaMassima IS NULL) AND
(Potenza <= PotenzaMassima OR PotenzaMassima IS NULL) AND
(Cilindrata <= CilindrataMassima OR CilindrataMassima IS NULL)
ORDER BY PesoMassimo
LIMIT 1;
RETURN ClasseTrovata;
END|
DELIMITER ;
