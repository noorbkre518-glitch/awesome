import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional() @IsString() @MaxLength(60)
  displayName?: string;

  @IsOptional() @IsString() @MaxLength(300)
  bio?: string;

  @IsOptional() @IsString() @MaxLength(2)
  country?: string;

  @IsOptional() @IsString() @MaxLength(120)
  languages?: string;
}
