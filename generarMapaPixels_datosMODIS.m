% Extraer datos de los ficheros MCD43B3 (Albedos) y representarlos usando
% c_map identificando el pixel AEMET
import matlab.io.hdfeos.*
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
[ficheroMODIS_B3, directorio] = uigetfile('*B3*.hdf','Seleccione el fichero');
if ~(ficheroMODIS_B1 == 0)
    dirMODIS_B3 = fullfile(directorio, ficheroMODIS_B3);
    structInfoMODIS = infoFicheroMODIS(ficheroMODIS_B3);
    structFile_B3 = hdfinfo(dirMODIS_B3, 'eos');
    % Grid details
    gfid = gd.open(dirMODIS_B3);
    GRID_NAME='MOD_Grid_BRDF';
    gridID = gd.attach(gfid, GRID_NAME);
    for i = 1:sum(~cellfun(@isempty,{structFile_B3.Grid.DataFields.Name}))
       [data, lat, lon] = gd.readField(gridID, structFile_B3.Grid.DataFields(i).Name);
        % Sustituye los valores 32767 por -1 para representarlos
        valoresNaN = data == 32767;
        data(valoresNaN) = NaN;
        s(1) = subplot(3, 1, 1);
        m_proj('lambert','long',[-12 0],'lat',[40 44]);
        m_pcolor(lon,lat,data);shading flat;
        m_coast;
        m_grid;
        [X,Y]=m_ll2xy(-3.724, 40.452);
        line(X,Y,'marker','square','markersize',4,'color','r');
        text(X,Y,'AEMET','vertical','middle');
        % Centrado en la AEMET
        [row_lon_Madrid, col_lon_Madrid] = find(lon < -3.5 & lon > -3.8);
        [row_lat_Madrid, col_lat_Madrid] = find(lat > 40.4 & lat < 40.5);
        row_Madrid = intersect(row_lon_Madrid, row_lat_Madrid);
        col_Madrid = intersect(col_lon_Madrid, col_lat_Madrid);
        lon_Madrid = lon(row_Madrid, col_Madrid);
        lat_Madrid = lat(row_Madrid, col_Madrid);
        data_Madrid = data(row_Madrid, col_Madrid);
        s(2) = subplot(3, 1, 2);
        m_proj('lambert', 'long',[min(min(lon_Madrid)) max(max(lon_Madrid))], ...
           'lat',[min(min(lat_Madrid)) max(max(lat_Madrid))]);
        m_pcolor(lon_Madrid, lat_Madrid, data_Madrid);shading flat;
        m_coast;
        m_grid;
        [X,Y]=m_ll2xy(-3.724, 40.452);
        line(X,Y,'marker','square','markersize',4,'color','r');
        text(X,Y,'AEMET','vertical','middle');
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
    title(s(1), ficheroMODIS_B3)
    title(s(2), [char(datetime(structInfoMODIS.fecha,'Format','dd/MM/yyyy')) ' + 16 días'])
    gd.detach(gridID);
    gd.close(gfid);
    % MODIS wavelengths
    % Band1: 620 - 670 nm (Red), Band2:	841 - 876 (NIR), Band3: 459 - 479 nm (Blue),
    % Band4: 545 - 565 nm (Green), Band5: 1230 - 1250 nm (1.2), Band6: 1628 - 1652 nm (1.6)
    % Band7: 2105 - 2155 nm (2.1), shortwave: 0.3 - 5.0 um, visible: 0.3 - 0.7 um
    % and near-infrared: 0.7 to 5.0 um (nir)  
    wvlMODIS = [645, 859, 469, 555, 1240, 1640, 2130];
    BlackAlbedo = [structAlbedos.Albedo_BSA_Band1, structAlbedos.Albedo_BSA_Band2, structAlbedos.Albedo_BSA_Band3, structAlbedos.Albedo_BSA_Band4, structAlbedos.Albedo_BSA_Band5, structAlbedos.Albedo_BSA_Band6, structAlbedos.Albedo_BSA_Band7];
    s(3) = subplot(3, 1, 3);
    plot(wvlMODIS, BlackAlbedo, '+r');
    WhiteAlbedo = [structAlbedos.Albedo_WSA_Band1, structAlbedos.Albedo_WSA_Band2, structAlbedos.Albedo_WSA_Band3, structAlbedos.Albedo_WSA_Band4, structAlbedos.Albedo_WSA_Band5, structAlbedos.Albedo_WSA_Band6, structAlbedos.Albedo_WSA_Band7];
    hold on;
    plot(wvlMODIS, WhiteAlbedo, 'ob');
    hold off;
    nombreFicheroFIG = sprintf('%s%s%s%s', 'PixelAEMET_', datestr(structInfoMODIS.fecha, 'yyyymmdd'), '_row', num2str(row_lon_AEMETpixel), '_col', num2str(col_lat_AEMETpixel(1)),  '.fig');
    saveas(gca, nombreFicheroFIG);
    xlabel('Wavelengths (nm)');
    ylabel('Albedo');
    legend({'BSA', 'WSA'});
else
    msgbox('No se seleccionó ningún fichero. Procesamiento abortado');
end %if