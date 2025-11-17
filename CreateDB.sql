-- GRUPO 15

CREATE DATABASE BD2_TPI_G15
GO

USE BD2_TPI_G15;
GO

CREATE TABLE Liga (
    idLiga INT IDENTITY (1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL, 
    pais VARCHAR(50) NOT NULL, 
    division VARCHAR(20) NOT NULL, 
);
GO

CREATE TABLE Temporada (
    idTemporada INT IDENTITY (1,1) PRIMARY KEY,
    anio VARCHAR (20) NOT NULL,
    idLiga INT NOT NULL,
    inicio DATE NOT NULL,
    fin DATE NOT NULL, 
    CONSTRAINT FK_Temporada_Liga FOREIGN KEY (idLiga) REFERENCES Liga(idLiga)
)

CREATE TABLE Estadio (
    idEstadio INT IDENTITY (1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    ciudad VARCHAR(50),
    capacidad INT,
    direccion VARCHAR(100)
);
GO

CREATE TABLE Equipo (
    idEquipo INT IDENTITY (1,1) PRIMARY KEY, 
    idLiga INT NOT NULL, 
    nombre VARCHAR(50) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    fundacion DATE NOT NULL,
    idEstadio INT NULL,
    CONSTRAINT FK_Equipo_Liga FOREIGN KEY (idLiga) REFERENCES Liga (idLiga),
    CONSTRAINT FK_Equipo_Estadio FOREIGN KEY (idEstadio) REFERENCES Estadio (idEstadio)
);
GO

CREATE TABLE Jugador (
    idJugador INT IDENTITY (1,1) PRIMARY KEY, 
    idEquipo INT NULL, 
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(30) NOT NULL,
    nacimiento DATE NOT NULL,
    dni VARCHAR(20) NOT NULL UNIQUE,
    nacionalidad VARCHAR(50) NOT NULL,
    posicion VARCHAR(50) NOT NULL,
    retirado BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Jugador_Equipo FOREIGN KEY (idEquipo) REFERENCES Equipo (idEquipo)
);
GO

CREATE TABLE Partido (
    idPartido INT IDENTITY (1,1) PRIMARY KEY,
    idEstadio INT NULL,
    idLiga INT NOT NULL,
    idLocal INT NOT NULL, 
    idVisitante INT NOT NULL, 
    idTemporada INT NOT NULL,
    golesLocal INT,
    golesVisitante INT,
    fecha DATE NOT NULL,
    CONSTRAINT FK_Partido_Liga FOREIGN KEY (idLiga) REFERENCES Liga (idLiga),
    CONSTRAINT FK_Partido_Local FOREIGN KEY (idLocal) REFERENCES Equipo (idEquipo),
    CONSTRAINT FK_Partido_Visitante FOREIGN KEY (idVisitante) REFERENCES Equipo (idEquipo),
    CONSTRAINT FK_Partido_Estadio FOREIGN KEY (idEstadio) REFERENCES Estadio (idEstadio),
    CONSTRAINT FK_Partido_Temporada FOREIGN KEY (idTemporada) REFERENCES Temporada (idTemporada)
);
GO

CREATE TABLE EstadisticasxPartidoxEquipo (
    idEstadisticaEquipo INT IDENTITY (1,1) PRIMARY KEY,
    idEquipo INT NOT NULL,
    idPartido INT NOT NULL,
    posesion DECIMAL(5,2),
    tirosTotales INT,
    tirosAlArco INT,
    tarjetasAmarillas INT,
    tarjetasRojas INT,
    goles INT,
    CONSTRAINT FK_StatsEquipo_Equipo FOREIGN KEY (idEquipo) REFERENCES Equipo (idEquipo),
    CONSTRAINT FK_StatsEquipo_Partido FOREIGN KEY (idPartido) REFERENCES Partido (idPartido)
);
GO

CREATE TABLE EstadisticasxPartidoxJugador (
    idEstadisticaJugador INT IDENTITY (1,1) PRIMARY KEY,
    idJugador INT NOT NULL,
    idPartido INT NOT NULL,
    minutos INT,
    goles INT,
    asistencias INT,
    tarjetasAmarillas INT,
    tarjetasRojas INT,
    CONSTRAINT FK_StatsJugador_Jugador FOREIGN KEY (idJugador) REFERENCES Jugador (idJugador),
    CONSTRAINT FK_StatsJugador_Partido FOREIGN KEY (idPartido) REFERENCES Partido (idPartido)
);
GO

CREATE TABLE Historial (
    idHistorial INT IDENTITY (1,1) PRIMARY KEY,
    idLiga INT NOT NULL,
    idTemporada INT NOT NULL,
    idCampeon INT NOT NULL,
    idSubcampeon INT NOT NULL,
    puntosCampeon INT,
    victoriasCampeon INT,
    CONSTRAINT FK_Historial_Liga FOREIGN KEY (idLiga) REFERENCES Liga (idLiga),
    CONSTRAINT FK_Historial_Campeon FOREIGN KEY (idCampeon) REFERENCES Equipo (idEquipo),
    CONSTRAINT FK_Historial_Subcampeon FOREIGN KEY (idSubcampeon) REFERENCES Equipo (idEquipo),
    CONSTRAINT FK_Historial_Temporada FOREIGN KEY (idTemporada) REFERENCES Temporada (idTemporada)
);
GO

CREATE TABLE Promedio (
    idPromedio INT IDENTITY (1,1) PRIMARY KEY,
    idEquipo INT NOT NULL,
    idLiga INT NOT NULL,
    partidosTotales INT,
    puntosTotales INT,
    promedio DECIMAL(5,3),
    CONSTRAINT FK_Promedio_Equipo FOREIGN KEY (idEquipo) REFERENCES Equipo (idEquipo),
    CONSTRAINT FK_Promedio_Liga FOREIGN KEY (idLiga) REFERENCES Liga (idLiga)

);
