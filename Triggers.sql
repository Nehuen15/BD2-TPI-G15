USE BD2_TPI_G15;
GO

------ TRIGGER 1 - Ejecuta el procedimiento actualizar promedio al insertar un partido
CREATE OR ALTER TRIGGER tr_Actualizar_Promedio
ON Partido 
AFTER INSERT
AS
BEGIN
    DECLARE @idPartido INT;

    SELECT @idPartido = idPartido FROM inserted;

    IF @idPartido IS NULL
    BEGIN
        RAISERROR('No se pudo obtener el ID del partido insertado',16,1);
        RETURN;
    END

    EXEC sp_ActualizarPromedio @idPartido;
END

GO
------ TRIGGER 2 - Realiza la baja logica de un Jugador en lugar de fisica
CREATE OR ALTER TRIGGER tr_delete_Jugador
ON Jugador
INSTEAD OF DELETE
AS
BEGIN
    UPDATE J
    SET J.Retirado = 1,
        J.idEquipo = NULL
    FROM Jugador J
    INNER JOIN deleted D ON J.idJugador = D.idJugador;
END

GO
------ TRIGGER 3 - Crea una fila en ambas tablas de estadistica al insertar un partido
CREATE OR ALTER TRIGGER tr_create_estadistica
ON Partido
AFTER INSERT
AS
BEGIN
    DECLARE @idPartido INT, @idLocal INT, @idVisitante INT, @golesLocal INT, @golesVisitante INT;

    SELECT 
        @idPartido = idPartido,
        @idLocal = idLocal,
        @idVisitante = idVisitante,
        @golesLocal = golesLocal,
        @golesVisitante = golesVisitante
    FROM inserted;

    INSERT INTO EstadisticasxPartidoxEquipo (idEquipo, idPartido, posesion, tirosTotales, tirosAlArco, tarjetasAmarillas, tarjetasRojas, goles)
    VALUES
        (@idLocal, @idPartido, 0, 0, 0, 0, 0, @golesLocal),
        (@idVisitante, @idPartido, 0, 0, 0, 0, 0, @golesVisitante);

    INSERT INTO EstadisticasxPartidoxJugador (idJugador, idPartido, minutos, goles, asistencias, tarjetasAmarillas, tarjetasRojas)
    SELECT 
        J.idJugador, 
        @idPartido, 
        0, 0, 0, 0, 0
    FROM Jugador J
    INNER JOIN Equipo E ON E.idEquipo = J.idEquipo
    WHERE E.idEquipo IN (@idLocal, @idVisitante);
END

GO

------ TRIGGER 4 - Crea un promedio cuando se inserta un nuevo equipo o en caso de cambio de liga
CREATE OR ALTER TRIGGER tr_create_promedio
ON Equipo
AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO Promedio (idEquipo, idLiga, partidosTotales, puntosTotales, promedio)
    SELECT 
        i.idEquipo,
        i.idLiga,
        0, 0, 0
    FROM inserted i
    LEFT JOIN deleted d ON i.idEquipo = d.idEquipo
    WHERE d.idEquipo IS NULL; 

    INSERT INTO Promedio (idEquipo, idLiga, partidosTotales, puntosTotales, promedio)
    SELECT 
        i.idEquipo,
        i.idLiga,
        0, 0, 0
    FROM inserted i
    INNER JOIN deleted d ON i.idEquipo = d.idEquipo
    WHERE i.idLiga <> d.idLiga
      AND NOT EXISTS (
            SELECT 1 
            FROM Promedio p 
            WHERE p.idEquipo = i.idEquipo 
              AND p.idLiga = i.idLiga
        );
END