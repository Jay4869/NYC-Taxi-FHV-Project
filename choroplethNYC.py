from __future__ import print_function, division
import os
import sys
import geopandas as gpd
import pylab as pl
import optparse
import matplotlib as mpl
import numpy as np

DEBUG = True
DEBUG = False

#for python 2/3 compatibility
try:
    rawinput = raw_input
except NameError:
    rawinput = input

def discrete_cmap(N, base_cmap=None):
    '''Create an N-bin discrete colormap from the specified input map
    from Jake VanDerPlas with minor modifications to let it with with divergent cmaps
    https://gist.github.com/jakevdp/91077b0cae40f8f8244a#file-discrete_cmap-py-L18
    Arguments:
    N : number of colors
    base_cmap : a pylab cmap name (string) or pylab cmap object'''
    # Note that if base_cmap is a string or None, you can simply do
    #    return plt.cm.get_cmap(base_cmap, N)
    # The following works for string, None, or a colormap instance:

    from matplotlib.colors import LinearSegmentedColormap
    base = pl.cm.get_cmap(base_cmap)
    color_list = base(np.linspace(0, 1, N))
    cmap_name = base.name + str(N)
    return LinearSegmentedColormap.from_list(cmap_name, color_list, N)


def choroplethNYC(df, column=None, cmap='viridis', ax=None,
                  cb=True, kind='continuous', alpha=1, color=None, edgecolor=None,
                  scheme=None, k=10, spacing=False, lw=1, width=None, side=False):
    '''creates a choroplath from a dataframe column - NYC tuned
    Arguments:
    df : a GeoDataFrame
    column : a column name 
    cmap : colorman name (string optional)
    ax : axis in figure object (string, optiona, is None a figure is created)
    cb : put the color bar. Bool, default is True
    kind : 
    spacing : the spacing for the colorbar (bool, optional)
    lw : line width (float, optional, default is 1)
    width : with width of the color bar (figure frction, float)
    side : default False is left (west), True switches to right (east). If a float is passed that is the location
    Returns the figure and the axis, for further manipulation
    '''
    if ax == None:
        ax = pl.figure(figsize=(10, 10)).add_subplot(111)
    if column == None:
        if color == None:
            ax = df.plot(cmap=cmap, alpha=alpha, ax=ax, linewidth=lw)
        else:
            ax = df.plot(alpha=alpha, ax=ax, linewidth=lw, color=color, edgecolor=edgecolor)
    elif not scheme == None:
        ax = df.plot(column=column, edgecolor=edgecolor,
                     cmap=cmap, alpha=alpha, ax=ax,
                     linewidth=lw, scheme=scheme, k=k, legend=True)
 
        pl.legend(loc=2)
        ax.axis('off')
        leg = ax.get_legend()
        #pl.legend(bbox_to_anchor=(2, 2), loc=2, borderaxespad=0)
        leg.set_bbox_to_anchor((0.35, 0.95, 0, 0))

        fig = ax.get_figure()
        return None, ax, leg                     
    else:
        if kind == 'continuous' and not isinstance(df[column].values[0], (int, float)):
            try:
                df[column] =  df[column].astype(float)
                df[column].replace(np.inf, np.nan, inplace=True)
            except ValueError:
                kind = 'discrete'
      
        ax = df.dropna(subset=[column]).plot(column=column, edgecolor=edgecolor,
                                             cmap=cmap, alpha=alpha, ax=ax,
                                             linewidth=lw)

        vmin, vmax = min(df[column].values), max(df[column].values)
    ax.axis('off')
    fig = ax.get_figure()

    if column == None:
        return fig, ax

    #if  discrete variable you want steps cb
    if kind is 'discrete':
        nc = df[column].unique()
        cmap = discrete_cmap(len(nc), base_cmap=cmap)

    # location of colorbar is tuned to the shape of NYC: sits above SI, west of Manhattan
    if cb:
        if not side:
            x0 = 0.2
        elif isinstance(side, float):
            x0 = side
        else:
            x0 = 0.9
        if not width:
            width = 0.03

        cax = fig.add_axes([x0, 0.41, width, 0.44])

        if kind is 'discrete':
            sm = mpl.colorbar.ColorbarBase(ax=cax, cmap=cmap,
                                norm=pl.Normalize(vmin=vmin - .5,
                                                  vmax=vmax + .5),
                                #spacing='uniform',
                                orientation='vertical')

        else:
            sm = mpl.colorbar.ColorbarBase(ax=cax, cmap=cmap,
                                norm=pl.Normalize(vmin=vmin, vmax=vmax),
                                ticks=range(spacing + 1),
                                spacing='uniform',
                                orientation='vertical')

        sm._A = []

        if  kind is 'discrete':
            cb = fig.colorbar(sm, cax=cax, ticks=np.linspace(vmin, vmax, len(nc)))
            cb.ax.set_yticklabels(['%s' % (c) for c in np.sort(nc)])
        else:
            cb = fig.colorbar(sm, cax=cax)
    return fig, ax, cb


if __name__ == '__main__':
    parser = optparse.OptionParser(usage="choroplathNYC <path to shapefile> <column>", conflict_handler="resolve")
    parser.add_option('-d', '--discrete', default=False, action="store_true",
	                      help='discrete steps color bar')
    parser.add_option('-m', '--cmap', default='viridis', type='string',
	                      help='matplotlib colormap name')
    parser.add_option('-t', '--title', default=None, type='string',
	                      help='title of figure')
    parser.add_option('-o', '--output', default=None, type='string',
	                      help='''output file 
(must be pylab compatible extension, e.g. pdf png etc''')
    parser.add_option('--clobber', default=False, action="store_true",
	                      help='''clobber output file''')
    parser.add_option('--noshow', default=False, action="store_true",
	                      help='do not show figure (default)')
    parser.add_option('--debug', default=False, action="store_true",
	                      help='print debug statements')

 
    options,  args = parser.parse_args()
    if options.debug:
        DEBUG = True
    if DEBUG:
        print (options)
        print (args)
    
    if len(args) == 0:
        options, args = parser.parse_args(args=['--help'])
        sys.exit(0)
    if args[0].endswith("shp"):
        gdf = gpd.read_file(args[0])
    else:
        options, args = parser.parse_args(args=['--help'])
        sys.exit(0)
    if DEBUG: print (gdf.head())
    
    kind = 'continous'
    if options.discrete:
        kind = 'discrete'

    if len(args)>1:
        if args[1] in gdf.columns:
            try:
                gdf[args[1]] = gdf[args[1]].astype(float)
            
            except ValueError:
                print ("the requested column cannot be converted to nuerical values. Available columns:",
            gdf.columns)
                sys.exit()
            fig, ax, cb = choroplethNYC(gdf, args[1], cmap=options.cmap,
                                    kind=kind)
        else:
            print ("column", args[1], "not in file. Available columns:",
            gdf.columns)
            sys.exit()
    else: 
        fig, ax = choroplethNYC(gdf, cmap=options.cmap)
    
    if not options.title is None:
        ax.set_title(options.title, fontsize=20)
        
    if not options.output is None:
        if os.path.isfile(options.output) and not options.clobber:
            answer = rawinput("file exists, really replace? (Y/n)\n")
            if (answer.startswith('Y') or answer.startswith('y') or
                answer.startswith('')):
                fig.savefig(options.output, clobber=True)
        else:
            fig.savefig(options.output, clobber=True)            
    else:
        if not options.noshow:
            pl.show()
