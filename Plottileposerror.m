figure();
plot((positionArray(:,3)-positionArray(:,5))*1E3);%X
hold on
plot((positionArray(:,4)-positionArray(:,6))*1E3); %Y
ylabel('Error in microns');
xlabel('tile number');
legend('X','Y');
