% Extraer datos de los ficheros MCD43B1 (coeficientes f) y MCD43B3 (Albedos)
% de MODIS
import matlab.io.hdfeos.*
structParam = struct('BRDF_Albedo_Parameters_Band1', [0, 0, 0], 'BRDF_Albedo_Parameters_Band2', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_Band3', [0, 0, 0], 'BRDF_Albedo_Parameters_Band4', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_Band5', [0, 0, 0], 'BRDF_Albedo_Parameters_Band6', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_Band7', [0, 0, 0], 'BRDF_Albedo_Parameters_vis', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_nir', [0, 0, 0], 'BRDF_Albedo_Parameters_shortwave', [0, 0, 0]);
structAlbedos = struct('Albedo_BSA_Band1', {0}, 'Albedo_BSA_Band2', {0}, ...
                        'Albedo_BSA_Band3', {0}, 'Albedo_BSA_Band4', {0}, ...
                        'Albedo_BSA_Band5', {0}, 'Albedo_BSA_Band6', {0}, ...
                        'Albedo_BSA_Band7', {0}, 'Albedo_BSA_vis', {0}, ...
                        'Albedo_BSA_nir', {0}, 'Albedo_BSA_shortwave', {0}, ...
                        'Albedo_WSA_Band1', {0}, 'Albedo_WSA_Band2', {0}, ...
                        'Albedo_WSA_Band3', {0}, 'Albedo_WSA_Band4', {0}, ...
                        'Albedo_WSA_Band5', {0}, 'Albedo_WSA_Band6', {0}, ...
                        'Albedo_WSA_Band7', {0}, 'Albedo_WSA_vis', {0}, ...
                        'Albedo_WSA_nir', {0}, 'Albedo_WSA_shortwave', {0});
cd('\\cendat2\lidar\\Satelites\MODIS\Datos\MCD43B3_Albedo_Madrid');
[ficheroMODIS_B1, directorio] = uigetfile('*B1*.hdf','Seleccione el fichero');
if ~(ficheroMODIS_B1 == 0)
    % Extrae la fecha del nombre del fichero MODIS
    % MCD43B1.A2012225.h17v04.005.2012242130041.hdf
    structInfoMODIS = infoFicheroMODIS(ficheroMODIS_B1);
    dirMODIS_B1 = fullfile(directorio, ficheroMODIS_B1);
    structFile_B1 = hdfinfo(dirMODIS_B1, 'eos');
    % Grid details
    gfid = gd.open(dirMODIS_B1);
    GRID_NAME='MOD_Grid_BRDF';
    gridID = gd.attach(gfid, GRID_NAME);
    for i = 1:sum(~cellfun(@isempty,{structFile_B1.Grid.DataFields.Name})) 
        [data, lat, lon] = gd.readField(gridID, structFile_B1.Grid.DataFields(i).Name);
        [row_lat_AEMETpixel, col_lat_AEMETpixel] = find(abs(lat - 40.452) == min(min(abs(lat - 40.452))));
        row_lon_AEMETpixel = find(abs(abs(lon(:, col_lat_AEMETpixel(1))) - 3.742) == min(abs(abs(lon(:, col_lat_AEMETpixel(1))) - 3.742)));
        scale_factor = 0.001; % Reference: https://lpdaac.usgs.gov/dataset_discovery/modis/modis_products_table/mcd43b1
        coefF_AEMET = scale_factor * double(data(:, row_lon_AEMETpixel, col_lat_AEMETpixel(1)));
        structParam.(structFile_B1.Grid.DataFields(i).Name) = coefF_AEMET';
    end %for
    % Cambia al fichero con White_Sky_Albedo y Black_Sky_Albedo
    % MCD43B3.A2012225.h17v04.005.2012242130041.hdf
    ficheroMODIS_B3 =  strrep(ficheroMODIS_B1, 'B1', 'B3');            
    dirMODIS_B3 = fullfile(directorio, ficheroMODIS_B3);
    structFile_B3 = hdfinfo(dirMODIS_B3, 'eos');
    % Grid details
    gfid = gd.open(dirMODIS_B3);
    GRID_NAME='MOD_Grid_BRDF';
    gridID = gd.attach(gfid, GRID_NAME);
    for i = 1:sum(~cellfun(@isempty,{structFile_B3.Grid.DataFields.Name}))
       [data, lat, lon] = gd.readField(gridID, structFile_B3.Grid.DataFields(i).Name);
%         % Sustituye los valores 32767 por -1 para representarlos
%         valoresNaN = data == 32767;
%         data(valoresNaN) = NaN;
%         s(1) = subplot(3, 1, 1);
%         m_proj('lambert','long',[-12 0],'lat',[40 44]);
%         m_pcolor(lon,lat,data);shading flat;
%         m_coast;
%         m_grid;
%         [X,Y]=m_ll2xy(-3.724, 40.452);
%         line(X,Y,'marker','square','markersize',4,'color','r');
%         text(X,Y,'AEMET','vertical','middle');
%         % Centrado en la AEMET
%         [row_lon_Madrid, col_lon_Madrid] = find(lon < -3.5 & lon > -3.8);
%         [row_lat_Madrid, col_lat_Madrid] = find(lat > 40.4 & lat < 40.5);
%         row_Madrid = intersect(row_lon_Madrid, row_lat_Madrid);
%         col_Madrid = intersect(col_lon_Madrid, col_lat_Madrid);
%         lon_Madrid = lon(row_Madrid, col_Madrid);
%         lat_Madrid = lat(row_Madrid, col_Madrid);
%         data_Madrid = data(row_Madrid, col_Madrid);
%         s(2) = subplot(3, 1, 2);
%         m_proj('lambert', 'long',[min(min(lon_Madrid)) max(max(lon_Madrid))], ...
%            'lat',[min(min(lat_Madrid)) max(max(lat_Madrid))]);
%         m_pcolor(lon_Madrid, lat_Madrid, data_Madrid);shading flat;
%         m_coast;
%         m_grid;
%         [X,Y]=m_ll2xy(-3.724, 40.452);
%         line(X,Y,'marker','square','markersize',4,'color','r');
%         text(X,Y,'AEMET','vertical','middle');
%         [X,Y]=m_ll2xy(-3.7257, 40.4565);
%         line(X,Y,'marker','square','markersize',4,'color','r');
%         text(X,Y,'CIEMAT','vertical','top');
        % Extrae el valor del pixel de la AEMET
        [row_lat_AEMETpixel, col_lat_AEMETpixel] = find(abs(lat - 40.452) == min(min(abs(lat - 40.452))));
        row_lon_AEMETpixel = find(abs(abs(lon(:, col_lat_AEMETpixel(1))) - 3.742) == min(abs(abs(lon(:, col_lat_AEMETpixel(1))) - 3.742)));
        scale_factor = 0.001; % Reference: https://lpdaac.usgs.gov/dataset_discovery/modis/modis_products_table/mcd43b3
        data_Madrid = scale_factor * double(data(row_lon_AEMETpixel, col_lat_AEMETpixel(1)));
        structAlbedos.(structFile_B3.Grid.DataFields(i).Name) = data_Madrid;
    end
%     title(s(1), ficheroMODIS_B3)
%     title(s(2), [char(datetime(structInfoMODIS.fecha,'Format','dd/MM/yyyy')) ' + 16 días'])
    gd.detach(gridID);
    gd.close(gfid);
    % MODIS wavelengths
    % Band1: 620 - 670 nm (Red), Band2:	841 - 876 (NIR), Band3: 459 - 479 nm (Blue),
    % Band4: 545 - 565 nm (Green), Band5: 1230 - 1250 nm (1.2), Band6: 1628 - 1652 nm (1.6)
    % Band7: 2105 - 2155 nm (2.1), shortwave: 0.3 - 5.0 um, visible: 0.3 - 0.7 um
    % and near-infrared: 0.7 to 5.0 um (nir)  
    wvlMODIS = [645, 859, 469, 555, 1240, 1640, 2130];
    BlackAlbedo = [structAlbedos.Albedo_BSA_Band1, structAlbedos.Albedo_BSA_Band2, structAlbedos.Albedo_BSA_Band3, structAlbedos.Albedo_BSA_Band4, structAlbedos.Albedo_BSA_Band5, structAlbedos.Albedo_BSA_Band6, structAlbedos.Albedo_BSA_Band7];
%     s(3) = subplot(3, 1, 3);
%     plot(wvlMODIS, BlackAlbedo, '+r');
    WhiteAlbedo = [structAlbedos.Albedo_WSA_Band1, structAlbedos.Albedo_WSA_Band2, structAlbedos.Albedo_WSA_Band3, structAlbedos.Albedo_WSA_Band4, structAlbedos.Albedo_WSA_Band5, structAlbedos.Albedo_WSA_Band6, structAlbedos.Albedo_WSA_Band7];
%     hold on;
%     plot(wvlMODIS, WhiteAlbedo, 'ob');
%     hold off;
    % Busca los datos coincidentes temporalmente de AERONET
%     version = 2;
%     nivel = 15;
%     [Albedos] = buscarAlbedosAERONET(fechaAERONET, version, nivel);
%     SZA = Albedos.SZA;
%     wvlAERONET = [440, 675, 870, 1020];
    % Conversion a albedo
%     WSA = fiso + fvol * (0.189184) + fgeo * (-1.377622);     
%     BSA = fiso + ...
%            fvol * (-0.007574 - 0.070987 * szen_sqr + 0.307588 * szen_cub) + ...
%            fgeo * (-1.284909 - 0.166314 * szen_sqr + 0.041840 * szen_cub);
    structWS_Constants = struct('WS_iso', {1.0}, 'WS_vol', {0.189184}, ...
                        'WS_geo', {-1.377622});
    structBS_Constants = struct('BS_g0_iso', {1.0}, 'BS_g0_vol', {-0.007574}, ...
                        'BS_g0_geo', {-1.284909}, 'BS_g1_iso', {0.0}, ...
                        'BS_g1_vol', {-0.070987}, 'BS_g1_geo', {-0.166314}, ...
                        'BS_g2_iso', {0.0}, 'BS_g2_vol', {0.307588}, ...
                        'BS_g2_geo', {0.04184});
    % Calcula WSA y BSA para cada banda
    newBS_Albedo = zeros(1, 10);
    newWS_Albedo = zeros(1, 10);
    for indexBand = 1:10 % 7 bands + vis + nir + sw. No shape indicators
        SZArad = 0;
        newBS_Albedo(1, indexBand) = (structBS_Constants.BS_g0_iso + ...
                    structBS_Constants.BS_g1_iso * SZArad^2 + ...
                    structBS_Constants.BS_g2_iso * SZArad^3) * ...
                    structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(1) + ...
                   (structBS_Constants.BS_g0_vol + ...
                    structBS_Constants.BS_g1_vol * SZArad^2 + ...
                    structBS_Constants.BS_g2_vol * SZArad^3) * ...
                    structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(2) + ...
                   (structBS_Constants.BS_g0_geo + ...
                    structBS_Constants.BS_g1_geo * SZArad^2 + ...
                    structBS_Constants.BS_g2_geo * SZArad^3) * ...
                    structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(3);
        newWS_Albedo(1, indexBand) = structWS_Constants.WS_iso*structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(1) + ...
                    structWS_Constants.WS_vol*structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(2) + ...
                    structWS_Constants.WS_geo*structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(3);
    end % for indexBand
    s(1) = subplot(2, 1, 1);
    plot(wvlMODIS, BlackAlbedo, '+r');
    hold on;
    plot(wvlMODIS, WhiteAlbedo, 'or');
    plot(wvlMODIS, newBS_Albedo(1:length(wvlMODIS)), '+k');
    plot(wvlMODIS, newWS_Albedo(1:length(wvlMODIS)), 'ok');
    hold off;
    xlabel('Wavelengths (nm)');
    ylabel('Albedos');
    Titulo(1) = {'Comparacion B1 y B3 para:'};
    Titulo(2) = {ficheroMODIS_B3};
    title(Titulo);
    legend({'BSA B3', 'WSA B3', 'BSA B1', 'WSA B1'});
    s(2) = subplot(2, 1, 2);
    plot(wvlMODIS, (100*(BlackAlbedo - newBS_Albedo(1:length(wvlMODIS)))./BlackAlbedo), '+k');
    hold on;
    plot(wvlMODIS, (100*(WhiteAlbedo - newWS_Albedo(1:length(wvlMODIS)))./WhiteAlbedo), 'ok');
    hold off;
    xlabel('Wavelengths (nm)');
    ylabel('Residuals (%)');
    legend({'BSA', 'WSA'});
    nombreFicheroFIG = sprintf('%s%s%s%s', 'CompWSAyBSA_', datestr(structInfoMODIS.fecha, 'yyyymmdd'), '_FicherosMCD43B1y3.fig');
    saveas(gca, nombreFicheroFIG);
else
    msgbox('No se seleccionó ningún fichero. Procesamiento abortado');
end %if