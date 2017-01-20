function [structInfoMODIS] = infoFicheroMODIS(ficheroMODIS)
    % Extrae la fecha del nombre del fichero MODIS
    % MCD43B3.A2012225.h17v04.005.2012242130041.hdf
    % Output: estructura con la informacion del nombre del fichero
    structInfoMODIS = struct('tipoFichero', {''}, 'fecha', {0}, ...
        'cuadricula', {0}, 'version', {0}, 'fechaProcesamiento', {0}, 'ext', {''});
    [structInfoMODIS.tipoFichero, resto] = strtok(ficheroMODIS, '.');
    [fechaYDiaAgno_txt, resto] = strtok(resto, '.');
    [cuadricula_txt, resto] = strtok(resto, '.');
    [structInfoMODIS.version, resto] = strtok(resto, '.');
    [fechaProcesamiento_txt, resto] = strtok(resto, '.');
    [structInfoMODIS.ext, ~] = strtok(resto, '.');
    fechaYDiaAgno = sscanf(fechaYDiaAgno_txt, 'A%4d%3d');
    structInfoMODIS.fecha = datevec(doy2date(fechaYDiaAgno(2), fechaYDiaAgno(1)));
    structInfoMODIS.cuadricula = sscanf(cuadricula_txt, 'h%2dv%2d');
    fechaYDiaAgnoProc = sscanf(fechaProcesamiento_txt, '%4d%3d%2d%2d%2d');
    vectorProc = datevec(doy2date(fechaYDiaAgnoProc(2), fechaYDiaAgnoProc(1)));
    structInfoMODIS.fechaProcesamiento = [vectorProc(1), vectorProc(2), ...
        vectorProc(3), fechaYDiaAgnoProc(3), fechaYDiaAgnoProc(4), ...
        fechaYDiaAgnoProc(5)];
end
