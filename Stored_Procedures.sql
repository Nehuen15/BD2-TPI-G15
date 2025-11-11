USE BD2_TPI_G15;
GO

------ PROCEDIMIENTO 1 - Calcula el promedio de un equipo
CREATE OR ALTER PROCEDURE sp_ActualizarPromedioPorEquipo (@idEquipo INT) AS
BEGIN
    IF EXISTS (SELECT 1 FROM Promedio WHERE idEquipo = @idEquipo AND partidosTotales > 0)
    BEGIN
        UPDATE Promedio
        SET promedio = CAST(puntosTotales AS DECIMAL(5,3)) / partidosTotales
        WHERE idEquipo = @idEquipo;
    END
END

GO

------ PROCEDIMIENTO 2 - Actualiza el promedio segun el partido

CREATE OR ALTER PROCEDURE sp_ActualizarPromedio (@IDPartido INT) AS
BEGIN
    DECLARE @EquipoLocal INT, 
            @EquipoVisitante INT, 
            @GolesLocal INT, 
            @GolesVisitante INT,
            @idLiga INT

    SELECT 
        @EquipoLocal = P.idLocal,
        @EquipoVisitante = P.idVisitante,
        @GolesLocal = P.golesLocal,
        @GolesVisitante = P.golesVisitante,
        @idLiga = idLiga
    FROM Partido P
    WHERE P.idPartido = @IDPartido;

    IF @EquipoLocal IS NOT NULL AND @EquipoVisitante IS NOT NULL
    BEGIN
        
        UPDATE Promedio 
        SET partidosTotales = partidosTotales + 1 
        WHERE idEquipo IN (@EquipoLocal, @EquipoVisitante);
    
        IF @GolesLocal > @GolesVisitante
        BEGIN
            UPDATE Promedio SET puntosTotales = puntosTotales + 3 WHERE idEquipo = @EquipoLocal AND idLiga = @idLiga;
        END
        ELSE IF @GolesLocal < @GolesVisitante
        BEGIN
            UPDATE Promedio SET puntosTotales = puntosTotales + 3 WHERE idEquipo = @EquipoVisitante AND idLiga = @idLiga;
        END
        ELSE
        BEGIN
            UPDATE Promedio SET puntosTotales = puntosTotales + 1 WHERE idEquipo IN (@EquipoLocal, @EquipoVisitante) AND idLiga = @idLiga;
        END

        EXEC sp_ActualizarPromedioPorEquipo @EquipoLocal;
        EXEC sp_ActualizarPromedioPorEquipo @EquipoVisitante;
    END
END

GO

------ PROCEDIMIENTO 3 - Muestra las estadisticas de un jugador entra la fechas indicadas
CREATE OR ALTER PROCEDURE sp_estadisticaPorJugadorPorFechas (@idJugador INT, @FechaInicio DATE, @FechaFin DATE) AS
BEGIN
    SELECT 
		J.Nombre,
		J.Apellido,
		E.Nombre 'Equipo',
		SUM(EPJ.Goles) 'Goles',
		SUM(Epj.asistencias) 'Asistencias',
		SUM(EPJ.minutos) 'Minutos',
		SUM(EPJ.tarjetasAmarillas) 'Tarjetas Amarillas',
		SUM(EPJ.tarjetasRojas) 'Tarjetas Rojas' 
	FROM EstadisticasxPartidoxJugador EPJ
    INNER JOIN Jugador J ON J.idJugador = EPJ.idJugador
    INNER JOIN Partido P ON P.idPartido = EPJ.idPartido
    INNER JOIN Equipo E ON E.idEquipo = J.idEquipo
    WHERE EPJ.idJugador = @idJugador AND P.fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY 
		J.nombre,
		J.apellido,
		E.nombre;
END

GO
------ PROCEDIMIENTO 4 - Muestra la tabla de una temporada de una liga
CREATE OR ALTER PROCEDURE sp_tablaDePosicionesPorTemporada (@idLiga INT, @anio INT)AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Temporada WHERE anio = @anio)
    BEGIN
        RAISERROR ('No existe registro para esa temporada', 16,1)
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Temporada WHERE idLiga = @idLiga)
    BEGIN
        RAISERROR ('No existe registro para esa liga', 16,1)
        RETURN;
    END
    
    SELECT * from vista_tabla_posiciones_futbol
    WHERE anio = @anio AND idLiga = @idLiga
    ORDER BY Puntos DESC;
END


GO
------ PROCEDIMIENTO 5 - Inserta un Equipo y verifica que no haya otro equipo con ese nombre
CREATE OR ALTER PROCEDURE sp_ingresarEquipo (@idLiga INT, @nombre VARCHAR(50), @ciudad VARCHAR(50), @fundacion DATE) AS
BEGIN
    IF EXISTS (SELECT 1 FROM Equipo E WHERE E.nombre = @nombre)
    BEGIN
        RAISERROR('Ya existe un equipo con ese nombre',16,1);
        RETURN;
    END
    ELSE
    BEGIN
    INSERT INTO Equipo (IdLiga, nombre, ciudad,fundacion) VALUES
        (@IdLiga,@nombre,@ciudad,@fundacion);
    END
END

GO
------ PROCEDIMIENTO 6 - Inserta un Jugador
CREATE OR ALTER PROCEDURE sp_ingresarJugador (
    @idEquipo INT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(30),
    @nacimiento DATE,
    @nacionalidad VARCHAR(50),
    @posicion VARCHAR(50)
)
AS
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Equipo WHERE idEquipo = @idEquipo)
    BEGIN
        RAISERROR('El equipo especificado no existe.',16,1);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1 
        FROM Jugador 
        WHERE nombre = @nombre 
          AND apellido = @apellido 
          AND nacimiento = @nacimiento
    )
    BEGIN
        RAISERROR('Ya existe un jugador con ese nombre y fecha de nacimiento.',16,1);
        RETURN;
    END;

    INSERT INTO Jugador (idEquipo, nombre, apellido, nacimiento, nacionalidad, posicion)
    VALUES (@idEquipo, @nombre, @apellido, @nacimiento, @nacionalidad, @posicion);
END

GO
------ PROCEDIMIENTO 7 - Insertar un Partido y verifica que los ambos equipos existan, que los equipos no sean iguales, pertenezcan a la misma liga y que no tengan otro partido en la misma fecha

CREATE OR ALTER PROCEDURE sp_ingresarPartido (@idEstadio INT,@IdLiga INT, @idLocal INT, @idVisitante INT, @idTemporada INT, @golesLocal INT, @golesVisitante INT,@fecha DATE) AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Equipo E WHERE E.idEquipo = @idLocal)
    BEGIN
        RAISERROR ('El equipo local no existe',16,1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Equipo E WHERE E.idEquipo = @idVisitante)
    BEGIN
        RAISERROR ('El equipo Visitante no existe',16,1);
        RETURN;
    END

    IF (SELECT idLiga FROM Equipo WHERE idEquipo = @idLocal) <> (SELECT idLiga FROM Equipo WHERE idEquipo = @idVisitante)
    BEGIN
        RAISERROR ('Los equipos no pertenecen a la misma liga',16,1);
        RETURN;
    END

    IF @IdLiga <> (SELECT idLiga FROM Equipo WHERE idEquipo = @idLocal) AND @IdLiga <> (SELECT idLiga FROM Equipo WHERE idEquipo = @idVisitante)
    BEGIN
        RAISERROR ('La liga ingresada no corresponde con la de los equipos',16,1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Partido WHERE (idLocal = @idLocal OR idVisitante = @idVisitante OR idLocal = @idVisitante OR idVisitante = @idLocal) AND @fecha = fecha)
    BEGIN
        RAISERROR ('Uno de los equipos ya tiene un partido en esta fecha',16,1);
        RETURN;
    END

    IF @idLocal = @idVisitante
    BEGIN
        RAISERROR ('Los equipos son iguales',16,1);
        RETURN;
    END
    
    INSERT INTO Partido (idEstadio, idLiga, idLocal, idVisitante, idTemporada, golesLocal,golesVisitante,fecha) VALUES
        (@idEstadio, @IdLiga, @idLocal, @idVisitante,@idTemporada,@golesLocal,@golesVisitante, @fecha);
END

GO
------ PROCEDIMIENTO 8 - Alta Historial y verifica que los equipos no sean igual y que no exista un historial para esa temporada y liga 
CREATE OR ALTER PROCEDURE sp_InsertarHistorial (@idLiga INT, @idTemporada INT, @idCampeon INT,
														@idSubcampeon INT, @puntosCampeon INT, @victoriasCampeon INT) AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM Historial 
        WHERE idLiga = @idLiga AND idTemporada = @idTemporada
    )
    BEGIN
        RAISERROR ('Ya existe un historial para esta liga y temporada',16,1);
        RETURN;
    END
    IF @idCampeon = @idSubcampeon
    BEGIN
        RAISERROR ('El equipo campeón y subcampeón no pueden ser el mismo',16,1);
        RETURN;
    END

    IF @idLiga <> (SELECT idLiga FROM Temporada WHERE idTemporada = @idTemporada)
    BEGIN
        RAISERROR ('La temporada indicada no pertenece a la liga seleccionada',16,1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 
        FROM Equipo 
        WHERE idEquipo IN (@idCampeon, @idSubcampeon)
        AND idLiga <> @idLiga
    )
    BEGIN
        RAISERROR ('Uno de los equipos no pertenece a la liga especificada',16,1);
        RETURN;
    END

    INSERT INTO Historial (idLiga, idTemporada, idCampeon, idSubcampeon, puntosCampeon, victoriasCampeon)
    VALUES (@idLiga, @idTemporada, @idCampeon, @idSubcampeon, @puntosCampeon, @victoriasCampeon);
END

GO
------ PROCEDIMIENTO 9 - Alta Temporada y verificacion si no hay registrada una temporada y liga iguales
CREATE OR ALTER PROCEDURE sp_insertarTemporada (@anio VARCHAR (20), @idLiga INT, @inicio DATE,@fin DATE) AS
BEGIN
    IF @inicio > @fin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser posterior a la fecha de fin',16,1);
        RETURN;
    END

    IF EXISTS 
    (
        SELECT 1 
        FROM Temporada 
        WHERE idLiga = @idLiga 
        AND anio = @anio
    )
    BEGIN
        RAISERROR('Ya existe una temporada para esa liga y año',16,1);
        RETURN;
    END

    INSERT INTO Temporada (anio, idLiga, inicio, fin) 
    VALUES (@anio, @idLiga, @inicio, @fin);
END

GO
------ PROCEDIMIENTO 10 - Actualizacion estadistica de jugadores
CREATE OR ALTER PROCEDURE sp_actualizarEstadisticaDeJugador (@idJugador INT,@idPartido INT ,
					@minutos INT,@goles INT,@asistencias INT,@tarjetasAmarillas INT,@tarjetasRojas INT) AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Jugador WHERE idJugador = @idJugador)
    BEGIN
        RAISERROR('El jugador especificado no existe',16,1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Partido WHERE idPartido = @idPartido)
    BEGIN
        RAISERROR('El partido especificado no existe',16,1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1 
        FROM EstadisticasxPartidoxJugador 
        WHERE idJugador = @idJugador AND idPartido = @idPartido
    )
    BEGIN
        RAISERROR('No existe un registro de estadística para este jugador y partido',16,1);
        RETURN;
    END

    UPDATE EstadisticasxPartidoxJugador 
    SET minutos = @minutos, 
        goles = @goles, 
        asistencias = @asistencias, 
        tarjetasAmarillas = @tarjetasAmarillas, 
        tarjetasRojas = @tarjetasRojas
    WHERE idJugador = @idJugador AND idPartido = @idPartido;
END


GO
------ PROCEDIMIENTO 11 - Actualizacion estadistica de equipos
CREATE OR ALTER PROCEDURE sp_actualizarEstadisticaDeEquipo(@idEquipo INT,@idPartido INT ,
	@posesion DECIMAL(5,2),@tirosTotales INT,@tirosAlArco INT,@tarjetasAmarillas INT,@tarjetasRojas INT) AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Equipo WHERE idEquipo = @idEquipo)
    BEGIN
        RAISERROR('El equipo especificado no existe',16,1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Partido WHERE idPartido = @idPartido)
    BEGIN
        RAISERROR('El partido especificado no existe',16,1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1 
        FROM EstadisticasxPartidoxEquipo 
        WHERE idEquipo = @idEquipo AND idPartido = @idPartido
    )
    BEGIN
        RAISERROR('No existe un registro de estadística para este equipo y partido',16,1);
        RETURN;
    END

    UPDATE EstadisticasxPartidoxEquipo 
    SET posesion = @posesion, 
        tirosTotales = @tirosTotales, 
        tirosAlArco = @tirosAlArco, 
        tarjetasAmarillas = @tarjetasAmarillas, 
        tarjetasRojas = @tarjetasRojas
    WHERE idEquipo = @idEquipo AND idPartido = @idPartido;
END

GO
------ PROCEDIMIENTO 12 - Muestra el historial de campeones segun la liga
CREATE OR ALTER PROCEDURE sp_historialCampeonesPorLiga (@idLiga INT) AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Liga WHERE idLiga = @idLiga)
    BEGIN
        RAISERROR ('No existe esa liga', 16,1)
        RETURN;
    END
    
    SELECT * FROM view_Historial_Campeones WHERE Liga = (SELECT nombre FROM Liga L WHERE L.idLiga = @idLiga)
    ORDER BY Puntos DESC

END

