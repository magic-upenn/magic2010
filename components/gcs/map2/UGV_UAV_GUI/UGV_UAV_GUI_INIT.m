function UGV_UAV_GUI_INIT
global GUI_CONTAINER G_MAP_PLOT R1_MAP_PLOT R2_MAP_PLOT R3_MAP_PLOT


GUI_CONTAINER=figure(108111108);%,'WindowButtonMotionFcn',@resizeCallBack);
set(GUI_CONTAINER,'position',[670 150 860 740])
clf

colormap(hot)

G_MAP_PLOT.axes=axes;
G_MAP_PLOT.width=.5;
G_MAP_PLOT.height=.5;
G_MAP_PLOT.plot=imagesc(flipud(zeros(10)));

PLOT_WIDTH=.28;
R1_MAP_PLOT.axes=axes;
R1_MAP_PLOT.width=PLOT_WIDTH;
R1_MAP_PLOT.height=PLOT_WIDTH;
R1_MAP_PLOT.plot=plot(0,0);

R2_MAP_PLOT.axes=axes;
R2_MAP_PLOT.width=PLOT_WIDTH;
R2_MAP_PLOT.height=PLOT_WIDTH;
R2_MAP_PLOT.plot=plot(0,0);

R3_MAP_PLOT.axes=axes;
R3_MAP_PLOT.width=PLOT_WIDTH;
R3_MAP_PLOT.height=PLOT_WIDTH;
R3_MAP_PLOT.plot=plot(0,0);

set(G_MAP_PLOT.axes,'Position',[.05 .97-G_MAP_PLOT.width G_MAP_PLOT.width G_MAP_PLOT.height]);
set(R1_MAP_PLOT.axes,'Position',[.64 .97-R1_MAP_PLOT.width R1_MAP_PLOT.width R1_MAP_PLOT.height]);
set(R2_MAP_PLOT.axes,'Position',[.64 .64-R2_MAP_PLOT.width R2_MAP_PLOT.width R2_MAP_PLOT.height]);
set(R3_MAP_PLOT.axes,'Position',[.64 .31-R3_MAP_PLOT.width R3_MAP_PLOT.width R3_MAP_PLOT.height]);

%set(G_MAP_PLOT.axes,'XTick',[],'YTick',[],'XColor',get(gcf,'color'),'YColor',get(gcf,'color'))
%set(R1_MAP_PLOT.axes,'XTick',[],'YTick',[],'XColor',get(gcf,'color'),'YColor',get(gcf,'color'))
%set(R2_MAP_PLOT.axes,'XTick',[],'YTick',[],'XColor',get(gcf,'color'),'YColor',get(gcf,'color'))
%set(R3_MAP_PLOT.axes,'XTick',[],'YTick',[],'XColor',get(gcf,'color'),'YColor',get(gcf,'color'))

set(G_MAP_PLOT.axes,'PlotBoxAspectRatio',[1.3 1 1]);
set(R1_MAP_PLOT.axes,'PlotBoxAspectRatio',[1.3 1 1]);
set(R2_MAP_PLOT.axes,'PlotBoxAspectRatio',[1.3 1 1]);
set(R3_MAP_PLOT.axes,'PlotBoxAspectRatio',[1.3 1 1]);

axis(G_MAP_PLOT.axes,'equal')
axis(R1_MAP_PLOT.axes,'equal')
axis(R2_MAP_PLOT.axes,'equal')
axis(R3_MAP_PLOT.axes,'equal')

end