
clear; close all; 

whichplot = 'neutral'; % slow or fast or neutral.
ifmakemovie = 1; % Make movie = 1 or not = 0


 unqdeps = transpose(unique(0:50:2800)); P = length(unqdeps);


load('Vote_1_perc.mat') %LLVP plotting
load('Vote_Fast.mat')

           boja1 = [1 0 0]; boja2 = [252/255 161/255 3/255]; 
            color1 = [0 0 1]; color2 = [0 1 1];

    [lons,lats, deps] = meshgrid(linspace(0,360,361),linspace(-90,90,181), 6371- linspace(0, 2850, 57)); 
            V = vote_count; 
            VV= vote_count_fast;
  
V(:,:,unqdeps<2000) = 0; %Slow votes
VV(:,:,unqdeps<2000) = 0; %fast votes


r2d = pi/180; 

[X,Y,Z] = sph2cart(r2d*lons,r2d*lats,deps); 


%
figure; 
FV = isosurface(deps,lats,lons,V,7.8); 
FV2 = isosurface(deps,lats,lons,V,4.8); 

FVV =isosurface(deps,lats,lons,VV,7.8); 
FVV2 =isosurface(deps,lats,lons,VV,4.8); 

%
tmp = FV.vertices; 
[FV.vertices(:,1), FV.vertices(:,2), FV.vertices(:,3)] = sph2cart(r2d*tmp(:,3),r2d*tmp(:,2),tmp(:,1)); 
tmp2 = FV2.vertices; 
[FV2.vertices(:,1), FV2.vertices(:,2), FV2.vertices(:,3)] = sph2cart(r2d*tmp2(:,3),r2d*tmp2(:,2),tmp2(:,1)); 

tmp3 = FVV.vertices; 
[FVV.vertices(:,1), FVV.vertices(:,2), FVV.vertices(:,3)] = sph2cart(r2d*tmp3(:,3),r2d*tmp3(:,2),tmp3(:,1)); 
tmp4 = FVV2.vertices; 
[FVV2.vertices(:,1), FVV2.vertices(:,2), FVV2.vertices(:,3)] = sph2cart(r2d*tmp4(:,3),r2d*tmp4(:,2),tmp4(:,1)); 
%

close all; 
load topo; 
topo2 = topo(1:2:end,1:2:end); 
MyFigure = figure('position',[10 10 800 800]); 



set(MyFigure,'Renderer','OpenGL')
Scrnsz=get(0, 'ScreenSize');
set(gcf,'color','k')
%set(gcf,'Position',Scrnsz);
set(gcf,'Position',[10 10 800 600]); 
set(gca,'Color',[0.5 0.5 0.5]);
set(gcf,'Color',[0.5 0.5 0.5]);

set(MyFigure,'defaultaxesposition',[0 0 1 1])



p = patch(FV);hold on; 

set(p,'facecolor',boja1,'edgecolor','none'); 
p2 = patch(FV2); 
set(p2,'facecolor',boja2,'edgecolor','none'); 
indx = find(deps(:)<(6371-2699)); fkt = 6371/max(sqrt(Z(:).^2 + X(:).^2 + Y(:).^2));

f = patch(FVV); 
set(f,'facecolor',color1,'edgecolor','none'); 
f2 = patch(FVV2);
set(f2,'facecolor',color2,'edgecolor','none'); 

% Outer core
hh1 = surf( 1.*squeeze(X(:,:,end)),...
            1.*squeeze(Y(:,:,end)),...
            1.*squeeze(Z(:,:,end)));
        
% Surface 
hh2 = surf(fkt.*squeeze(X(:,:,1)),...
           fkt.*squeeze(Y(:,:,1)),...
           fkt.*squeeze(Z(:,:,1))); 
       
% Style the colored Earth Surface (hh2) using the global colormap
set(hh2, 'cdata', flipud(flipud(topo)), 'facecolor', 'texturemap', 'edgecolor', 'none');
colormap(demcmap(topo)); 
topo_min = min(topo(:));
topo_max = max(topo(:));
topo_norm = (topo - topo_min) / (topo_max - topo_min); 

%CONTRAST BOOST
topo_extreme = max(0, min(1, (topo_norm - 0.4) * 3)); 

topo_bw = repmat(topo_extreme, [1, 1, 3]); % Convert to 3-channel B&W RGB

%Apply the B&W texture map to the Outer Core (hh1)
set(hh1, 'cdata', flipud(flipud(topo_bw)), 'facecolor', 'texturemap', 'facealpha', 1, 'edgecolor', 'none'); 
alpha(p2,0.5); 
alpha(f2, 0.5);
alpha(hh2,0.2); 
daspect([1 1 1]); set(gca,'visible','off'); 
camlight('headlight'); 

% Brighten up the global baseline shadows 
light('Position',[1 1 1], 'Style', 'infinite', 'Color', [0.4 0.4 0.4]);

% Change material properties so it doesn't reflect like polished chrome
material metal; 
lighting phong;
view(0,0); 
%
axis vis3d
set(MyFigure,'color','w');

if(ifmakemovie)
    
    % Create Video Object
    
    % Video Variables and Settings
    %-----------------------------
    
    %MyMovieMaker = VideoWriter('Acoustical Cavity','MPEG-4');
    MyMovieMaker = VideoWriter(['Spinning Earth Final Models ' whichplot ' Majority '],'Motion JPEG AVI');

    MyMovieMaker.Quality=100;
    MyMovieMaker.FrameRate=30;
    open(MyMovieMaker);
    for i=1:180
        camorbit(2,0,'data',[0 0 -1])
        drawnow
        %Record_Video_Frame
        
        Current_Frame=getframe(MyFigure);
        writeVideo(MyMovieMaker,Current_Frame);
    end
    %end
    close(MyMovieMaker);
end
% --- 3D MODEL EXPORT SECTION ---
disp('Exporting 3D scene elements to OBJ...');

% Export the 4 structural mesh patches
patch2obj('mesh_structure_slow_high.obj', FV);
patch2obj('mesh_structure_slow_half.obj', FV2);
patch2obj('mesh_structure_fast_high.obj', FVV);
patch2obj('mesh_structure_fast_half.obj', FVV2);

% Export the Outer Core (hh1 coordinates)
X_core = 1.*squeeze(X(:,:,end));
Y_core = 1.*squeeze(Y(:,:,end));
Z_core = 1.*squeeze(Z(:,:,end));
surf2obj('outer_core_globe.obj', X_core, Y_core, Z_core);

% Export the Earth Surface (hh2 coordinates)
X_surf = fkt.*squeeze(X(:,:,1));
Y_surf = fkt.*squeeze(Y(:,:,1));
Z_surf = fkt.*squeeze(Z(:,:,1));
surf2obj('earth_surface_globe.obj', X_surf, Y_surf, Z_surf);

disp('Export Complete! All layers saved as separate .obj files.');
% Bake textures matching the UV mapping
topo = topo*255;
% Single flips to counteract MATLAB matrix inversion
imwrite(flipud(topo), 'earth_color.png');
imwrite(flipud(topo_bw), 'outer_core_bw.png');

disp('Export Complete!');
